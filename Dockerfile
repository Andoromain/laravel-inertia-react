FROM php:8.2.5-apache

WORKDIR /var/www/html

# Install required system packages and PHP extensions
RUN apt-get update && \
    apt-get install -y \
    git \
    libzip-dev \
    libpng-dev \
    libicu-dev \
    libpq-dev \
    libmagickwand-dev \
    curl \
    gnupg \
    && docker-php-ext-install pdo_mysql zip exif pcntl bcmath gd && \
    a2enmod rewrite

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -  && \
    apt-get install -y nodejs

# Update Apache configuration for Laravel
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy application source code
COPY . /var/www/html

# Set ownership and permissions before running npm commands
RUN chown -R www-data:www-data /var/www/html

# Switch to the www-data user for npm commands
USER www-data

# Install PHP dependencies using Composer
RUN composer install --no-dev --prefer-dist --no-scripts --no-progress --no-suggest

# Install Node.js dependencies and build assets
# Set a non-root user (example: www-data)
USER root

# Ensure ownership of necessary directories
RUN mkdir -p /var/www/.npm && chown -R www-data:www-data /var/www/.npm
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

USER www-data

# Install dependencies
RUN npm install

RUN npm install 

RUN npm run build

RUN php artisan migrate --force

# Switch back to root to set final ownership
USER root

# Set proper permissions for the Laravel application
RUN chown -R www-data:www-data /var/www/html

# Expose the application on port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
