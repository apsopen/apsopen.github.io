let password = sessionStorage.getItem("clientPassword");

if (!password) {
    window.location.href = "/";
}


async function loadPackages() {

    const response = await fetch("data.json");
    const json = await response.json();

    const packages = document.getElementById("packages");
    const tools = document.getElementById("tools");


    json.data.forEach(item => {

        const card = createCard(item);

        if (item.tool === true) {
            tools.appendChild(card);
        } else {
            packages.appendChild(card);
        }

    });

}



function createCard(item) {

    const card = document.createElement("div");
    card.className = "package-card";


    let buttons = "";

    Object.entries(item.code).forEach(([action, script]) => {

        buttons += `
            <button
                class="install-button action-button"
                data-action="${action}"
                data-script="${script}"
            >
                ${action.charAt(0).toUpperCase() + action.slice(1)}
            </button>
        `;

    });


    card.innerHTML = `
        <img
            class="package-icon"
            src="${item.icon}"
            alt="${item.name}"
        >

        <div class="package-content">
            <h2>${item.name}</h2>
            <p>${item.description}</p>
        </div>

        <div class="package-actions">
            ${buttons}
        </div>
    `;


    card.querySelectorAll(".action-button").forEach(button => {

        button.onclick = () => {

            runScript(
                button.dataset.script,
                button.dataset.action,
                item.name,
                item.tool
            );

        };

    });


    return card;

}



async function runScript(scriptPath, action, packageName, isTool) {

    if (!isTool) {

        const confirmed = confirm(
            `Are you sure you want to ${action} ${packageName}?`
        );

        if (!confirmed) {
            return;
        }

    }


    const response = await fetch(scriptPath);


    if (!response.ok) {
        alert("Could not load script.");
        return;
    }


    const contents = await response.text();


    sendfile(password, contents);

}



function login() {

    const loginPassword = document.getElementById("toolbarPassword").value;


    if (!loginPassword) {
        alert("Enter your password.");
        return;
    }


    sessionStorage.setItem("clientPassword", loginPassword);


    window.location.href = "/signedin";

}



// Placeholder
function sendfile(password, contents) {

    console.log("User password:");
    console.log(password);

    console.log("Script contents:");
    console.log(contents);

}



loadPackages();