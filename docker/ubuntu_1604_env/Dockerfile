# Use the base image
FROM ubuntu:16.04

# Update package lists and install base tools
RUN apt-get update && \
    apt-get install -y sudo curl wget git nano vim unzip && \
    rm -rf /var/lib/apt/lists/*

# Create a user group with GID 1000
RUN groupadd -g 1000 khoa

# Create a user with UID 1000 and add to the group with GID 1000
RUN useradd -u 1000 -g 1000 -m -s /bin/bash khoa
RUN usermod -aG sudo khoa

# Grant the user sudo privileges (optional)
RUN echo 'khoa ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set the default user to khoa
USER khoa

# Set the command to run /data/run.sh
CMD ["bash"]
