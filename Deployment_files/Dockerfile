# Use the official Nginx image from the Docker Hub
FROM nginx:alpine

# Set the working directory
WORKDIR /usr/share/nginx/html

# Copy your static HTML files into the container
COPY index.html .

# Expose port 80 to the outside world
EXPOSE 80

# Start Nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]
