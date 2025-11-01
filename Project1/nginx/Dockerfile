# Start with the official, lightweight Nginx image
FROM nginx:stable-alpine

# Copy the custom Nginx configuration file.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# We have to make sure to copy them with the correct names for K8s and docker 
COPY ssl/nginx.crt /etc/nginx/ssl/tls.crt
COPY ssl/nginx.key /etc/nginx/ssl/tls.key

# Expose port 80 for HTTP (for the redirect) and 443 for HTTPS
EXPOSE 80
EXPOSE 443
# Start Nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]
