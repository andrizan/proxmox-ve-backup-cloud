#!/usr/bin/perl -w
# Hook script for vzdump to backup to an S3 bucket
# 2022 Andrew Palardy
# Based on example hook script from Proxmox

use strict;

# Define the name of your bucket here
my $bucket = "apalrd-proxmox";
# The S3 endpoint comes from the s3cmd --configure setup, it is not set here

# Define the number of days to retain backups in the bucket
# Only accepts days, doesn't check hours/minutes
my $retain = 30;


#Uncomment this to see the hook script with arguments (not required)
#print "HOOK: " . join (' ', @ARGV) . "\n";

#Get the phase from the first argument
my $phase = shift;

#For job-based phases
#Note that job-init was added in PVE 7.2 or 7.3 AFAIK
if (    $phase eq 'job-init'  ||
        $phase eq 'job-start' ||
        $phase eq 'job-end'   ||
        $phase eq 'job-abort') {

        #Env variables available for job based arguments
        my $dumpdir = $ENV{DUMPDIR};

        my $storeid = $ENV{STOREID};

        #Uncomment this to print the environment variables for debugging
        #print "HOOK-ENV: dumpdir=$dumpdir;storeid=$storeid\n";

        #Call s3cleanup at job end
        if ($phase eq 'job-end') {
                system ("/root/s3cleanup.sh $bucket \"$retain days\"");
        }
#For backup-based phases
} elsif ($phase eq 'backup-start' ||
         $phase eq 'backup-end' ||
         $phase eq 'backup-abort' ||
         $phase eq 'log-end' ||
         $phase eq 'pre-stop' ||
         $phase eq 'pre-restart' ||
         $phase eq 'post-restart') {

        #Data available to backup-based phases
        my $mode = shift; # stop/suspend/snapshot

        my $vmid = shift;

        my $vmtype = $ENV{VMTYPE}; # lxc/qemu

        my $dumpdir = $ENV{DUMPDIR};

        my $storeid = $ENV{STOREID};

        my $hostname = $ENV{HOSTNAME};

        my $tarfile = $ENV{TARGET};

        my $logfile = $ENV{LOGFILE};

        #Uncomment this to print environment variables
        #print "HOOK-ENV: vmtype=$vmtype;dumpdir=$dumpdir;storeid=$storeid;hostname=$hostname;tarfile=$tarfile;logfile=$logfile\n";

        # During backup-end, copy the target file to S3 and delete the original on the system
        if ($phase eq 'backup-end') {
                #S3 put
                my $result = system ("s3cmd put $tarfile s3://$bucket/");
                #rm original
                system ("rm $tarfile");
                #Die of error returned
                if($result != 0) {
                        die "upload backup failed";
                }
        }

        # During log-end, copy the log file to S3 and delete the original on the system (same as target file)
        if ($phase eq 'log-end') {
                my $result = system ("s3cmd put $logfile s3://$bucket/");
                system ("rm $logfile");
                if($result != 0) {
                        die "upload logfile failed";
                }
        }
#Otherwise, phase is unknown
} else {

        die "got unknown phase '$phase'";

}

exit (0);
