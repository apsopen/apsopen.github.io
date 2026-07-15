let password = sessionStorage.getItem("clientPassword");

if (!password) {
    window.location.href = "/";
}


async function loadPackages() {

    const response = await fetch("data.json");
    const json = await response.json();

    const container = document.getElementById("packages");


    json.data.forEach(item => {

        const card = document.createElement("div");
        card.className = "package-card";


        card.innerHTML = `
            <img 
                class="package-icon"
                src="/icon/${item.icon}"
                alt="${item.name}"
            >

            <div class="package-content">
                <h2>${item.name}</h2>

                <p>
                    ${item.description}
                </p>
            </div>

            <button class="install-button">
                Install Package
            </button>
        `;


        card.querySelector(".install-button")
            .addEventListener("click", () => {
                installPackage(item.installCode);
            });


        container.appendChild(card);

    });

}



async function installPackage(codeFile) {

    const confirmed = confirm(
        "Are you sure you want to install this package?"
    );


    if (!confirmed) {
        return;
    }


    const response = await fetch(`/code/${codeFile}`);

    if (!response.ok) {
        alert("Could not find install file.");
        return;
    }


    const contents = await response.text();


    sendfile(password, contents);

}



// Placeholder
function sendfile(password, contents) {

    console.log("User password:");
    console.log(password);

    console.log("Install file contents:");
    console.log(contents);

}



loadPackages();