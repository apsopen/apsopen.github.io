function generateCommand() {
    const password = document.getElementById("password").value;

    const command =
`tmpdir=$(mktemp -d)
curl -L https://github.com/apsopen/install/archive/refs/heads/main.zip -o "$tmpdir/install.zip"
unzip -q "$tmpdir/install.zip" -d "$tmpdir"
mv "$tmpdir"/install-main/client ~/client
rm -rf "$tmpdir"
bash ~/client/install.sh "${password || "YOUR_PASSWORD"}"`;

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


function login() {
    const password = document.getElementById("toolbarPassword").value;

    if (!password) {
        alert("Enter your password.");
        return;
    }

    sessionStorage.setItem("clientPassword", password);

    window.location.href = "/signedin";
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