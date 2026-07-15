function generateCommand() {
    const password = document.getElementById("password").value;

    if (!password) {
        alert("Enter a password first.");
        return;
    }

    const code =
`curl https://example.com/install.sh | bash -s -- ${password}`;

    document.getElementById("command").textContent = code;
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