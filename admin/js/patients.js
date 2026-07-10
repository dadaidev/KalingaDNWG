// ==========================================
// Kalinga Clinic Portal - Patients
// ==========================================

// ---------- Logout ----------
function logout() {
    if (confirm("Are you sure you want to logout?")) {
        window.location.href = "login.html";
    }
}

// ---------- Elements ----------
const tbody = document.querySelector("tbody");

const addModal = document.getElementById("addModal");
const editModal = document.getElementById("editModal");
const deleteModal = document.getElementById("deleteModal");

const addForm = document.getElementById("addPatientForm");
const editForm = document.getElementById("editPatientForm");
const confirmDeleteBtn = document.getElementById("confirmDelete");

let selectedRow = null;

// ==========================================
// Search
// ==========================================

document.querySelector(".search-box input").addEventListener("keyup", function () {

    const value = this.value.toLowerCase();

    document.querySelectorAll("tbody tr").forEach(row => {

        row.style.display =
            row.innerText.toLowerCase().includes(value)
                ? ""
                : "none";

    });

});

// ==========================================
// OPEN MODALS
// ==========================================

document.querySelector(".add-btn").onclick = () => {

    addForm.reset();

    addModal.style.display = "flex";

};

// ==========================================
// CLOSE MODALS
// ==========================================

function closeAddModal() {

    addModal.style.display = "none";

}

function closeEditModal() {

    editModal.style.display = "none";

}

function closeDeleteModal() {

    deleteModal.style.display = "none";

}

// ==========================================
// ADD PATIENT
// ==========================================

addForm.addEventListener("submit", function (e) {

    e.preventDefault();

    const name =
        addForm.querySelector('input[type="text"]').value;

    const age =
        addForm.querySelector('input[type="number"]').value;

    const gender =
        addForm.querySelector("select").value;

    const diagnosis =
        addForm.querySelectorAll("input")[2].value;

    const id =
        String(tbody.rows.length + 1).padStart(3, "0");

    const row = tbody.insertRow();

    row.innerHTML = `
        <td>${id}</td>
        <td>${name}</td>
        <td>${age}</td>
        <td>${gender}</td>
        <td>${diagnosis}</td>
        <td><span class="active-status">Active</span></td>
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

    closeAddModal();

});

// ==========================================
// EDIT
// ==========================================

function openEdit(row) {

    selectedRow = row;

    document.getElementById("editName").value =
        row.cells[1].innerText;

    document.getElementById("editAge").value =
        row.cells[2].innerText;

    document.getElementById("editGender").value =
        row.cells[3].innerText;

    document.getElementById("editDiagnosis").value =
        row.cells[4].innerText;

    editModal.style.display = "flex";

}

editForm.addEventListener("submit", function (e) {

    e.preventDefault();

    selectedRow.cells[1].innerText =
        document.getElementById("editName").value;

    selectedRow.cells[2].innerText =
        document.getElementById("editAge").value;

    selectedRow.cells[3].innerText =
        document.getElementById("editGender").value;

    selectedRow.cells[4].innerText =
        document.getElementById("editDiagnosis").value;

    closeEditModal();

});

// ==========================================
// DELETE
// ==========================================

function openDelete(row) {

    selectedRow = row;

    deleteModal.style.display = "flex";

}

confirmDeleteBtn.onclick = function () {

    if (selectedRow) {

        selectedRow.remove();

    }

    closeDeleteModal();

};

// ==========================================
// VIEW
// ==========================================

function openView(row) {

    alert(
        "Patient : " + row.cells[1].innerText +
        "\nAge : " + row.cells[2].innerText +
        "\nGender : " + row.cells[3].innerText +
        "\nDiagnosis : " + row.cells[4].innerText
    );

}

// ==========================================
// BUTTON EVENTS
// ==========================================

function bindButtons(row) {

    row.querySelector(".view").onclick = () => openView(row);

    row.querySelector(".edit").onclick = () => openEdit(row);

    row.querySelector(".delete").onclick = () => openDelete(row);

}

document.querySelectorAll("tbody tr").forEach(bindButtons);

// ==========================================
// CLICK OUTSIDE MODAL
// ==========================================

window.onclick = function (e) {

    if (e.target == addModal)
        closeAddModal();

    if (e.target == editModal)
        closeEditModal();

    if (e.target == deleteModal)
        closeDeleteModal();

};