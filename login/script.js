function login() {

    const password =
        document.getElementById("password").value;


    if (!password) {

        alert("Enter your password.");
        return;

    }


    sessionStorage.setItem(
        "clientPassword",
        password
    );


    window.location.href = "/signedin";

}