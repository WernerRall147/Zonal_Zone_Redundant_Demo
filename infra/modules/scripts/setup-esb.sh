#!/bin/bash
# ESB Server Setup Script

echo "Installing dependencies..."
apt-get update
apt-get install -y openjdk-11-jdk

# ESB Setup would go here in a real deployment
mkdir -p /opt/esb

# Create a simple status endpoint
cat > /opt/esb/status.sh <<EOF
#!/bin/bash
echo "Content-type: text/html"
echo ""
echo "<!DOCTYPE html>"
echo "<html>"
echo "<head><title>ESB Status</title></head>"
echo "<body>"
echo "<h1>ESB Server</h1>"
echo "<p>Instance: \$(hostname)</p>"
echo "<p>Zone: \$(curl -s -H Metadata:true --noproxy '*' 'http://169.254.169.254/metadata/instance/compute/zone?api-version=2021-02-01&format=text')</p>"
echo "</body>"
echo "</html>"
EOF

chmod +x /opt/esb/status.sh

echo "ESB server setup completed."
