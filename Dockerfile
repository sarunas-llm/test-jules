# Stage 1: Builder
# This stage installs dependencies using uv
FROM python:3.12-slim AS builder

# Install uv
RUN pip install uv

# Set the working directory
WORKDIR /app

# Copy dependency definition files
COPY pyproject.toml uv.lock ./

# Install dependencies using uv into a specific directory
# We use --system to install into the global site-packages
# --no-cache to avoid caching packages in the build layer
# uv will automatically use uv.lock if present
RUN uv pip install --system --no-cache -r pyproject.toml


# Stage 2: Final Image
# This stage creates the final, lean image
FROM python:3.12-slim AS final

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Copy the installed packages from the builder stage
# This is the key to the multi-stage build, keeping the final image small
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

# Copy the installed executables from the builder stage
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy the application code
COPY main.py .

# Expose the port the app runs on
EXPOSE 8000

# Define the command to run the application
# --host 0.0.0.0 is essential to make the app accessible from outside the container
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
