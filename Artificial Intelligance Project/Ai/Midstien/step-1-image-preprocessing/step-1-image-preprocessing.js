// Step 1: Image Input and Preprocessing (simulated)

const imageInput = document.getElementById("imageInput");
const originalImage = document.getElementById("originalImage");
const imagePreviewContainer = document.getElementById("imagePreviewContainer");
const noImageMessage = document.getElementById("noImageMessage");
const simulateButton = document.getElementById("simulateButton");
const preprocessSteps = document.querySelectorAll(".preprocess-step");

// Display the chosen image so that students can visually connect
// the uploaded question with the subsequent preprocessing steps.
imageInput.addEventListener("change", (event) => {
  const file = event.target.files && event.target.files[0];
  if (!file) {
    originalImage.style.display = "none";
    noImageMessage.style.display = "block";
    return;
  }

  const reader = new FileReader();
  reader.onload = (e) => {
    originalImage.src = String(e.target?.result || "");
    originalImage.style.display = "block";
    noImageMessage.style.display = "none";
  };
  reader.readAsDataURL(file);
});

// Simulate the preprocessing pipeline by updating status badges.
// This does not modify pixels; instead, it explains the intent
// of each operation for an academic audience.
function resetPreprocessSteps() {
  preprocessSteps.forEach((step) => {
    step.classList.remove("active", "completed");
    const badge = step.querySelector(".status-badge");
    if (badge) {
      badge.textContent = "Waiting";
      badge.style.backgroundColor = "#ffffff";
      badge.style.color = "#495057";
      badge.style.borderColor = "#adb5bd";
    }
  });
}

function markStep(stepElement, state) {
  const badge = stepElement.querySelector(".status-badge");
  if (!badge) return;

  if (state === "active") {
    stepElement.classList.add("active");
    badge.textContent = "Running";
    badge.style.backgroundColor = "#e7f1ff";
    badge.style.color = "#0d6efd";
    badge.style.borderColor = "#0d6efd";
  } else if (state === "completed") {
    stepElement.classList.remove("active");
    stepElement.classList.add("completed");
    badge.textContent = "Completed";
    badge.style.backgroundColor = "#d1e7dd";
    badge.style.color = "#0f5132";
    badge.style.borderColor = "#198754";
  }
}

simulateButton.addEventListener("click", () => {
  // Run the three conceptual preprocessing steps in sequence.
  resetPreprocessSteps();

  const grayscaleStep = document.querySelector('[data-step="grayscale"]');
  const denoiseStep = document.querySelector('[data-step="denoise"]');
  const contrastStep = document.querySelector('[data-step="contrast"]');

  if (!grayscaleStep || !denoiseStep || !contrastStep) return;

  markStep(grayscaleStep, "active");

  // Use short timeouts purely to make the sequence visible during a live demo.
  setTimeout(() => {
    markStep(grayscaleStep, "completed");
    markStep(denoiseStep, "active");
  }, 700);

  setTimeout(() => {
    markStep(denoiseStep, "completed");
    markStep(contrastStep, "active");
  }, 1400);

  setTimeout(() => {
    markStep(contrastStep, "completed");
  }, 2100);
});
