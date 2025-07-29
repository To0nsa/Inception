# Use Debian Bullseye slim as a minimal, stable base (the penultimate Debian release)
FROM debian:bullseye-slim

# 1. Update package lists so we can install the latest upstream versions
# 2. Install nginx (the web server) and curl (useful for debugging/probing)
# 3. --no-install-recommends keeps the image small by omitting extra packages
# 4. Clean up apt cache to reduce image layer size
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      nginx \ 
      curl \
 && rm -rf /var/lib/apt/lists/*  # remove downloaded package lists

# Run NGINX in the foreground (daemon off) so that it stays as PID 1
# and Docker can manage its lifecycle and receive signals correctly
ENTRYPOINT ["nginx", "-g", "daemon off;"]
