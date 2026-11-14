(function () {
  if (!window.matchMedia || !window.matchMedia("(pointer: fine)").matches) {
    return;
  }

  const dot = document.createElement("div");
  dot.className = "cursor-dot";
  const ring = document.createElement("div");
  ring.className = "cursor-ring";
  document.body.appendChild(ring);
  document.body.appendChild(dot);

  let targetX = window.innerWidth / 2;
  let targetY = window.innerHeight / 2;
  let ringX = targetX;
  let ringY = targetY;

  document.addEventListener("mousemove", (event) => {
    targetX = event.clientX;
    targetY = event.clientY;
    dot.style.transform = `translate(${targetX}px, ${targetY}px)`;
  });

  function animate() {
    const ease = 0.15;
    ringX += (targetX - ringX) * ease;
    ringY += (targetY - ringY) * ease;
    ring.style.transform = `translate(${ringX}px, ${ringY}px)`;
    requestAnimationFrame(animate);
  }

  animate();
})();
