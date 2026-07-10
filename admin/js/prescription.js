// ======================================
// Kalinga Clinic Portal
// Prescriptions Page
// ======================================

// ---------- Logout ----------

function logout() {

    if (confirm("Are you sure you want to logout?")) {

        window.location.href = "login.html";

    }

}

// ---------- Elements ----------

const tbody = document.querySelector("tbody");

const searchInput = document.querySelector(".search-box input");

const addModal = document.getElementById("addModal");
const editModal = document.getElementById("editModal");
const deleteModal = document.getElementById("deleteModal");

const addForm = document.getElementById("addPrescriptionForm");
const editForm = document.getElementById("editPrescriptionForm");

const confirmDelete = document.getElementById("confirmDelete");

const closeButtons = document.querySelectorAll(".close");
const cancelButton = document.querySelector(".cancel-btn");

let selectedRow = null;

// ======================================
// Search
// ======================================

searchInput.addEventListener("keyup", function () {

    const value = this.value.toLowerCase();

    document.querySelectorAll("tbody tr").forEach(row => {

        row.style.display =
            row.innerText.toLowerCase().includes(value)
                ? ""
                : "none";

    });

});

// ======================================
// Open Add Modal
// ======================================

document.querySelector(".add-btn").onclick = function () {

    addForm.reset();

    addModal.style.display = "flex";

};

// ======================================
// Close Modals
// ======================================

function closeModal(modal) {

    modal.style.display = "none";

}

closeButtons.forEach(btn => {

    btn.onclick = function () {

        closeModal(addModal);

        closeModal(editModal);

        closeModal(deleteModal);

    };

});

cancelButton.onclick = function () {

    closeModal(deleteModal);

};

window.onclick = function (event) {

    if (event.target == addModal)
        closeModal(addModal);

    if (event.target == editModal)
        closeModal(editModal);

    if (event.target == deleteModal)
        closeModal(deleteModal);

};

// ======================================
// Add Prescription
// ======================================

addForm.addEventListener("submit", function (e) {

    e.preventDefault();

    const inputs = addForm.querySelectorAll("input");

    const patient = inputs[0].value;
    const medicine = inputs[1].value;
    const dosage = inputs[2].value;
    const frequency = inputs[3].value;
    const doctor = inputs[4].value;

    const id = "RX" + String(tbody.rows.length + 1).padStart(3, "0");

    const row = tbody.insertRow();

    row.innerHTML = `

        <td>${id}</td>

        <td>${patient}</td>

        <td>${medicine}</td>

        <td>${dosage}</td>

        <td>${frequency}</td>

        <td>${doctor}</td>

        <td>

            <span class="active-status">

                Active

            </span>

        </td>

        <td>

            <button class="view">

                <i class="fa-solid fa-eye"></i>

            </button>

            <button class="edit">

                <i class="fa-solid fa-pen"></i>

            </button>

            <button class="delete">

                <i class="fa-solid fa-trash"></i>

            </button>

        </td>

    `;

    bindButtons(row);

    closeModal(addModal);

});

// ======================================
// Edit Prescription
// ======================================

function openEdit(row) {

    selectedRow = row;

    document.getElementById("editPatient").value =
        row.cells[1].innerText;

    document.getElementById("editMedicine").value =
        row.cells[2].innerText;

    document.getElementById("editDosage").value =
        row.cells[3].innerText;

    document.getElementById("editFrequency").value =
        row.cells[4].innerText;

    document.getElementById("editDoctor").value =
        row.cells[5].innerText;

    editModal.style.display = "flex";

}

editForm.addEventListener("submit", function (e) {

    e.preventDefault();

    selectedRow.cells[1].innerText =
        document.getElementById("editPatient").value;

    selectedRow.cells[2].innerText =
        document.getElementById("editMedicine").value;

    selectedRow.cells[3].innerText =
        document.getElementById("editDosage").value;

    selectedRow.cells[4].innerText =
        document.getElementById("editFrequency").value;

    selectedRow.cells[5].innerText =
        document.getElementById("editDoctor").value;

    closeModal(editModal);

});

// ======================================
// Delete Prescription
// ======================================

function openDelete(row) {

    selectedRow = row;

    deleteModal.style.display = "flex";

}

confirmDelete.onclick = function () {

    if (selectedRow) {

        selectedRow.remove();

    }

    closeModal(deleteModal);

};

// ======================================
// View Prescription
// ======================================

function openView(row) {

    alert(

        "Prescription Information\n\n" +

        "Patient : " + row.cells[1].innerText + "\n" +

        "Medicine : " + row.cells[2].innerText + "\n" +

        "Dosage : " + row.cells[3].innerText + "\n" +

        "Frequency : " + row.cells[4].innerText + "\n" +

        "Doctor : " + row.cells[5].innerText + "\n" +

        "Status : " + row.cells[6].innerText

    );

}

// ======================================
// Bind Buttons
// ======================================

function bindButtons(row) {

    row.querySelector(".view").onclick = function () {

        openView(row);

    };

    row.querySelector(".edit").onclick = function () {

        openEdit(row);

    };

    row.querySelector(".delete").onclick = function () {

        openDelete(row);

    };

}

// ======================================
// Initialize Existing Rows
// ======================================

document.querySelectorAll("tbody tr").forEach(row => {

    bindButtons(row);

});

console.log("Prescriptions Page Loaded");