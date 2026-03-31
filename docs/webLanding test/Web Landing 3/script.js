const menuBtn = document.getElementById('menuBtn');
const nav = document.getElementById('nav');

menuBtn?.addEventListener('click', () => {
  nav.classList.toggle('open');
});

nav?.querySelectorAll('a').forEach((link) => {
  link.addEventListener('click', () => {
    nav.classList.remove('open');
  });
});

const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('active');
      }
    });
  },
  { threshold: 0.18 }
);

document.querySelectorAll('.reveal').forEach((el) => observer.observe(el));

const counters = document.querySelectorAll('.counter');
let counted = false;

function runCounters() {
  if (counted) return;
  const trigger = document.getElementById('plataforma');
  if (!trigger) return;
  const top = trigger.getBoundingClientRect().top;
  if (top < window.innerHeight * 0.8) {
    counted = true;
    counters.forEach((counter) => {
      const target = Number(counter.dataset.target || 0);
      let value = 0;
      const step = Math.max(1, Math.ceil(target / 35));
      const timer = setInterval(() => {
        value += step;
        if (value >= target) {
          value = target;
          clearInterval(timer);
        }
        counter.textContent = `${value}${target === 100 ? '%' : '+'}`;
      }, 30);
    });
  }
}

window.addEventListener('scroll', runCounters);
window.addEventListener('load', runCounters);
