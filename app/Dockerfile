FROM python:3.12-slim
RUN useradd -u 10001 app
WORKDIR /srv
COPY main.py .
USER 10001
EXPOSE 8080
CMD ["python", "main.py"]
