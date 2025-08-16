FROM python:3.8-slim

# Install poetry
RUN pip install poetry

# Set WORKDIR
WORKDIR /app

# Copy current directory to /app
COPY . /app

# Install dependencies
RUN poetry install --no-dev

# Expose port 5001
EXPOSE 5001

# Run application
CMD ["poetry", "run", "python3", "app.py"]