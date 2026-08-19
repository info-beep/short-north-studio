// Letter-split headline animation (word-grouped so lines never break mid-word)
(function(){
  const h = document.getElementById('headline');
  if(!h) return;
  const html = h.innerHTML;
  const parts = html.split(/(<br>|<span class="accent-line">|<\/span>)/);
  let out = '';
  let inAccent = false;
  let delay = 0.15;
  parts.forEach(part=>{
    if(part === '<br>'){ out += '<br>'; return; }
    if(part === '<span class="accent-line">'){ inAccent = true; return; }
    if(part === '</span>'){ inAccent = false; return; }
    part.split(' ').forEach((word, wi, arr)=>{
      out += '<span class="word">';
      word.split('').forEach(ch=>{
        const cls = inAccent ? 'char accent' : 'char';
        out += '<span class="'+cls+'" style="animation-delay:'+delay.toFixed(2)+'s">'+ch+'</span>';
        delay += 0.02;
      });
      out += '</span>';
      if(wi < arr.length - 1) out += ' ';
    });
  });
  h.innerHTML = out;
})();

// Ambient particles
(function(){
  const wrap = document.getElementById('particles');
  if(!wrap) return;
  const count = 22;
  for(let i=0;i<count;i++){
    const p = document.createElement('div');
    p.className = 'particle';
    const size = 2 + Math.random()*4;
    p.style.width = size+'px';
    p.style.height = size+'px';
    p.style.left = Math.random()*100+'%';
    p.style.bottom = '-5%';
    p.style.animationDuration = (10 + Math.random()*14)+'s';
    p.style.animationDelay = (Math.random()*14)+'s';
    wrap.appendChild(p);
  }
})();

// Scroll-driven hero parallax + progress bar + sticky header solid state
(function(){
  const heroWrap = document.querySelector('.hero-wrap');
  const videoLayer = document.getElementById('videoLayer');
  const heroContent = document.getElementById('heroContent');
  const progressBar = document.getElementById('progressBar');
  const header = document.getElementById('siteHeader');
  if(!heroWrap || !videoLayer || !heroContent) return;

  const heroWrapHeight = () => heroWrap.offsetHeight - window.innerHeight;

  function onScroll(){
    const scrollY = window.scrollY;
    const heroProgress = Math.min(1, Math.max(0, scrollY / heroWrapHeight()));

    videoLayer.style.transform = 'translate3d(0,' + (heroProgress * 60) + 'px,0)';
    heroContent.style.opacity = String(Math.max(0, 1 - heroProgress * 1.3));
    heroContent.style.transform = 'translate3d(0,' + (heroProgress * -40) + 'px,0)';

    const docHeight = document.documentElement.scrollHeight - window.innerHeight;
    progressBar.style.width = (docHeight > 0 ? (scrollY / docHeight * 100) : 0) + '%';

    if(header){
      header.classList.toggle('solid', scrollY > window.innerHeight * 0.7);
    }
  }
  window.addEventListener('scroll', onScroll, {passive:true});
  window.addEventListener('resize', onScroll);
  onScroll();
})();
