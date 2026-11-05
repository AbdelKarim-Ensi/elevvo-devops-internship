Task 5 of my Cloud & DevOps internship at @Elevvo is done ✅

I containerized a Node.js + MongoDB app:
🔹 Multi-stage Dockerfile (build separated from minimal Alpine runtime)
🔹 Non-root USER + healthcheck
🔹 docker-compose with a private internal bridge network, MongoDB port never exposed to the host
🔹 Credentials from environment variables, never committed
🔹 Bonus: Trivy scan for HIGH/CRITICAL CVEs

Skills: Docker, Docker Compose, privilege separation, bridge networking.

📂 Code: <LIEN_GITHUB>
🎥 Demo: <VIDEO_OU_LIEN>

#DevOps #Docker #DockerCompose #Security #Trivy #Elevvo #ElevvoInternship
