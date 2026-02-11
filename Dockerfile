# Minimal image for build → push → sign flow.
FROM alpine:3.19
RUN echo "demo-supply-chain" > /app.txt
CMD ["cat", "/app.txt"]
