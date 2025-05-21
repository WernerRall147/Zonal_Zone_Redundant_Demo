#!/bin/bash
# App Server Setup Script

echo "Installing dependencies..."
apt-get update
apt-get install -y nginx

# Configure nginx
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>App Server Demo</title>
</head>
<body>
    <h1>App Server</h1>
    <p>Instance: $(hostname)</p>
    <p>Zone: $(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/zone?api-version=2021-02-01&format=text")</p>
</body>
</html>
EOF

# Start services
systemctl enable nginx
systemctl restart nginx

echo "App server setup completed."
