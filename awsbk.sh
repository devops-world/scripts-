 #!/bin/bash
msg=""
echo "Choose your option:"
select opt in "Download & Install AWS script" "Configure AWS Authentication" "Setup S3 Backup Sync" "Remove S3 Backup Sync" "Set AWS Backup Bucket" "Run S3 Backup Now"  "Exit"
do
    clear
    echo $msg
    case $opt in
        Download* )
                curl https://raw.github.com/timkay/aws/master/aws -o aws>/dev/nul
                perl aws --install > /dev/nul
				aws 2>/dev/nul
				val=$(echo $?)
				if [ "$val" -eq "255" ]; then
					echo "Installed Successfully"
				elif [ "$val" -eq "127" ]; then				
					echo "aws script install seems to have failed."
				else 
					echo "aws script seems to have installed, but is returning an unexpected error"
				fi
        ;;
        Configure* )
                read -p "Enter your AWS Access Key ID: " accesskeyid
                read -p "Enter your AWS Secret Access Key: " secretaccesskey
                echo $accesskeyid>$home/.awssecret
                echo $secretaccesskey>>$home/.awssecret
                chmod 600 $home/.awssecret
                echo "file '/root/.awssecret' created and permissions set" 
        ;;
		Setup* )
			#download the backup script
			curl http://utmtools.com/sites/default/files/s3bak.sh.txt -o /usr/local/bin/s3bak.sh>/dev/nul
			chmod 700 /usr/local/bin/s3bak.sh
			echo "Download complete"
			#schedule the backup sync to run every 6 hours
			echo "# backup all config backups to Amazon S3 bucket"> /etc/crontab.s3bak
			RND=$(expr $RANDOM % 60)
			echo "$RND */6 * * *     root /usr/local/bin/s3bak.sh">> /etc/crontab.s3bak
			echo "">> /etc/crontab.s3bak
			
			#activate the schedule
			cat /etc/crontab-static /etc/crontab.*>/etc/crontab
			/etc/init.d/cron restart >/dev/nul
			echo "S3 Backup is installed and scheduled"
		;;
		Remove* )
			rm -f /etc/crontab.s3bak>/dev/nul
			rm -f /usr/local/bin/s3bak.sh>/dev/nul
			#activate the schedule
			cat /etc/crontab-static /etc/crontab.*>/etc/crontab
			/etc/init.d/cron restart >/dev/nul
			echo "S3 Backup is uninstalled, and the schedule was removed (if it was already installed)"
		;;		
		Set* )
			read -p "Enter the AWS bucket name to use: " -e "Backups" bucketname
			if [ -f "/root/.s3bak_settings" ]; then 
				grep -v "bucket=" /root/.s3bak_settings>/root/.s3bak_settings_
				echo "bucket=$bucketname">>/root/.s3bak_settings_
				mv -f /root/.s3bak_settings_ /root/.s3bak_settings
				echo "bucket=$bucketname">>/root/.s3bak_settings
			else
				echo "bucket=$bucketname">/root/.s3bak_settings
			fi
		;;
		Run* )
			/usr/local/bin/s3bak.sh
		;;
        * )
                echo "Bye."
                exit
        ;;
    esac
done
