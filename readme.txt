Ubuntu installation instructions:

1. Unzip the file

2. Install and configure a web server. Apache example:

   1. sudo apt-get install apache2

   2. sudo a2enmod rewrite

   3. Make important directories writable for Apache (replace $BIIGLE_DIR with the path
   	to the extracted ZIP):

      sudo chown -R www-data:www-data $BIIGLE_DIR/storage $BIIGLE_DIR/bootstrap/cache

      IMPORTANT: Both you and the webserver need to be able to write to these
      directories. If you can't log in or act as the webserver user (here www-data) this
      is what you could do:

      1. Create a new group for the users that should be able to perform maintenance
      	tasks for your Biigle instance (i.e. you):

      	sudo addgroup biigleadm
      	sudo usermod -a -G biigleadm yourusername

      2. Set the webserver user as owner and the new group as the group of the
      	directories:

      	sudo chown -R www-data:biigleadm $BIIGLE_DIR/storage $BIIGLE_DIR/bootstrap/cache

      3. Allow owner and group write permissions:

      	sudo chmod -R 775 $BIIGLE_DIR/storage $BIIGLE_DIR/bootstrap/cache

   4. Create new virtual host (replace biigle.org with your domain; you can also just
   	modify the default virtual host 000-default):

      sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/biigle.org.conf

   5. Edit the new host file:

   	sudo nano /etc/apache2/sites-available/biigle.org.conf

   	Set a ServerName like biigle.org (again, replace with your actual domain).
   	Set the DocumentRoot to $BIIGLE_DIR/public (again replace $BIIGLE_DIR with the
   	path to the extracted ZIP). Maybe set a ServerAlias or configure the ServerAdmin
   	or log paths.

   	Set directory options like these:

		<Directory $BIIGLE_DIR/public>
			Options FollowSymLinks
			AllowOverride all
			Order allow,deny
			Allow from all
			Require all granted
		</Directory>

   6. Enable the new virtual host:

   	sudo a2ensite biigle.org

   7. Restart Apache:

   	sudo service apache2 restart

3. Install PHP and extensions (version 5.6 or higher):

	sudo apt-get install php7.0 php7.0-json php7.0-pgsql php7.0-gd php7.0-mbstring php7.0-xml php7.0-soap php7.0-zip libapache2-mod-php7.0

4. Install and configure PostgreSQL
	(follow installation instructions like https://wiki.ubuntuusers.de/PostgreSQL/)

	Create a new DB user for the application:

	sudo -u postgres createuser -P -d biigle

	Create a new DB for the application:

	sudo -u postgres createdb -O biigle biigle

5. Install Supervisor and create a queue worker process:

	1. sudo apt-get install supervisor

	2. Create a file "/etc/supervisor/conf.d/biigle-worker.conf" with the content
		(again replace the two $BIIGLE_DIR, "www-data" must be the webserver user):

[program:biigle-worker]
process_name=%(program_name)s_%(process_num)02d
command=php $BIIGLE_DIR/artisan queue:work --sleep=5 --tries=3 --timeout=0
autostart=true
autorestart=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=$BIIGLE_DIR/storage/logs/worker.log

	3. Start supervisor (if it doesn't run already):

	sudo service supervisor start

	4. Start the worker process:

	sudo supervisorctl reread
	sudo supervisorctl update
	sudo supervisorctl start biigle-worker:*

6. Set up a cronjob for the task scheduler. Run "crontab -e" and add:

* * * * * php $BIIGLE_DIR/artisan schedule:run >> /dev/null 2>&1

7. Install Python requirements:

	sudo apt-get install libfreetype6-dev pkg-config python-dev python-pip python-matplotlib python-numpy python-scikits-learn python-scipy

	sudo pip install PyExcelerate

8. Finally configure Biigle:

	1. cd $BIIGLE_DIR

	2. Generate a new encryption key (do this only once!):

		php artisan key:generate

	3. Open $BIIGLE_DIR/.env in an editor and edit the following keys:

		- APP_URL: Must be the full URL to your Biigle insance, like "https://biigle.org"
		- ADMIN_EMAIL: (Your) email address that is used to contact the admin of the BIIGLE instance.
		- DB_DATABASE: Name of the database to use (in this example "biigle")
		- DB_USERNAME: Name of the database user (in this example "biigle")
		- DB_PASSWORD: Password of the database user (you chose this in step 4)
		- MAIL_ADDRESS: The email address to use as sender for all Biigle system mails

	4. Run the database migrations:

		php artisan migrate

	5. Run the post installation hooks. Since everything is already installed in the ZIP,
		this will just run all caching and optimization tasks for your machine:

		php composer.phar install

Now everything is up and running. Set up your first (admin) user with:

php artisan user:new

The laserpoint detection requires a global laserpoints label. To create this label,
select "New Label Tree" on the dashboard. Create a new label tree with a name like
"Global" (you can change that later) and make it public. Open the label tree and create
a new label "Laserpoint". As the first label of your Biigle instance, it will get the ID 1.
Now open $BIIGLE_DIR/config/laserpoints.php and replace "null" with "1". Last, click
"Leave" in the label tree overview to make the label tree global.
