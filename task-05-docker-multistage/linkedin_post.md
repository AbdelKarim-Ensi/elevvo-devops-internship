Task 5 of my Cloud & DevOps internship at Elevvo: multi-stage containerization and internal networking. 🐳

What I built: a todo-list app (Node.js) + PostgreSQL, containerized and orchestrated with Docker Compose.

What mattered most:

🔹 Multi-stage build: the runtime image keeps only what the app needs to run (62 MB of content).
🔹 Non-root: the container runs as uid 1000, never root.
🔹 Private networking: the database sits on an internal bridge network with no published port. From my host, port 5432 is closed. Only the app can reach it, by service name.
🔹 Security gate: Trivy scans the final image and blocks the run on HIGH/CRITICAL CVEs.

The scan was the best lesson. My first image had 29 findings: 7 in Alpine packages and 22 in npm's own internal dependencies. Patching the OS with apk upgrade and removing npm, yarn and corepack from the runtime image brought it to zero HIGH/CRITICAL. The best fix for a vulnerability in a tool you don't need at runtime is to not ship the tool.

Bonus debugging story: builds hung for minutes on Docker Desktop because the VM's bridge network could not reach the npm registry. Isolating the problem with timed npm ping tests on the host vs bridge network, then switching to the native engine, fixed it.

Code and demo in the repo: https://github.com/AbdelKarim-Ensi/elevvo-devops-internship

#DevOps #Docker #DockerCompose #Containers #DevSecOps #Trivy #CloudComputing #Elevvo
