function generateCommand() {
    const password = document.getElementById("password").value;

    const command =
`curl https://example.com/install.sh | bash -s -- ${password || "YOUR_PASSWORD"}`;

    document.getElementById("command").textContent = command;
}


function copyCommand() {
    const command = document.getElementById("command").textContent;

    navigator.clipboard.writeText(command);

    const button = document.querySelector(".copy-button");

    button.textContent = "Copied!";

    setTimeout(() => {
        button.textContent = "Copy";
    }, 1500);
}


function finishSetup() {
    const password = document.getElementById("password").value;

    if (!password) {
        alert("Enter your password first.");
        return;
    }

    sessionStorage.setItem("clientPassword", password);

    window.location.href = "/signedin";
}