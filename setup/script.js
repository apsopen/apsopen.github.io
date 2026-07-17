function generateCommand() {
    const password = document.getElementById("password").value;

    const command =
`mkdir -p ~/client

curl -L https://raw.githubusercontent.com/apsopen/apsopen.github.io/main/install/client/install.sh -o ~/client/install.sh
curl -L https://raw.githubusercontent.com/apsopen/apsopen.github.io/main/install/client/mountain-client -o ~/client/mountain-client

chmod +x ~/client/install.sh ~/client/mountain-client
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

async function getVersion() {
    const response = await fetch("/version.txt");


    if (!response.ok) {
        alert("Could not load script.");
        return;
    }


    var contents = await response.text();

    document.getElementById("site-name").textContent = contents;
}

getVersion()