username=$1
repository=$2
echo "Username: $username"
echo "Repository: $repository"

mkdir /var/www/$repository
cd /var/www/$repository

echo "";

echo -n "Enabling rewrite on apache...";
sudo a2enmod rewrite > /dev/null
echo " done";

echo -n "Installing composer...";
curl -sS https://getcomposer.org/installer | php > /dev/null
sudo mv composer.phar /usr/local/bin/composer > /dev/null
echo " done";

echo -n "Setting up ssh key...";
ssh-keygen -f ~/.ssh/id_rsa -N ''
echo " done";

echo "Add this to either:"
echo "   1. The deploy keys in the Github repo"
echo "   2. The SSH keys for a machine user"
echo "";
cat ~/.ssh/id_rsa.pub

echo "Done?"
read isDone

echo -n "Updating apt..."
sudo apt-get update
echo "done"

echo -n "Adding zip..."
sudo apt-get install -y php7.2-zip > /dev/null
echo "done"

echo -n "Adding php-mbstring..."
sudo apt-get install -y php7.2-mbstring > /dev/null
echo "done"
echo -n "Adding php-xml..."
sudo apt-get install -y php7.2-xml > /dev/null
echo "done";
echo -n "Adding php-curl..."
apt-get install -y php7.2-curl > /dev/null
echo "done";

echo -n "Cloning repo git@github.com:$username/$repository.git...";
cd ..
git clone git@github.com:$username/$repository.git > /dev/null
echo "done";

echo -n "Changing permissions...";
sudo chgrp -R www-data $repository
sudo chmod -R 770 $repository
echo " done";

echo -n "Installing composer...";
cd /var/www/$repository > /dev/null
composer install
echo "done";

read -r -p "Do you want to configure apache? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    echo -n "Configuring apache... "
    sudo sed -i "s/var\/www\/html/var\/www\/$repository\/current\/public/g" /etc/apache2/sites-enabled/000-default.conf
	echo "done"
fi

read -r -p "Do you want to install supervisord? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
then
    echo -n "Installing supervisord... "
    sudo apt-get install -y python-setuptools
	sudo easy_install supervisor
	sudo mkdir /etc/supervisor
	sudo su
	echo_supervisord_conf >  /etc/supervisor/supervisord.conf
	echo "done, feel free to configure it. (/etc/supervisor/supervisord.conf)"
fi

echo -n "Restarting apache...";
sudo service apache2 restart > /dev/null
echo "done";

echo -n "Updating .bashrc... ";
echo "" >> ~/.bashrc
echo "cd /var/www/$repository/current" >> ~/.bashrc
echo "done";

echo "";

echo "All done! Don't forget to copy in your .env!"
