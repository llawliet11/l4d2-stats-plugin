FROM node:18 as build

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Build the application
RUN npm run build

# Use a lightweight Node.js image for serving
FROM node:18-alpine

WORKDIR /app

# Install serve
RUN npm install -g serve

# Copy the built application from the build stage
COPY --from=build /app/dist /app

EXPOSE 8080

# Serve the application
CMD ["serve", "-s", ".", "-l", "8080"]
