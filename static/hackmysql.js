function artSort(btn, showId, hideId) {
	document.getElementById(showId).style.removeProperty('display');
	document.getElementById(hideId).style.setProperty('display', 'none', 'important');
	btn.parentElement.querySelectorAll('.art-btn').forEach(function(b) { b.classList.remove('active'); });
	btn.classList.add('active');
}
function zen() {
	document.getElementById("bird").classList.toggle('hide');
	document.getElementById("toc").classList.toggle('hide');
	document.getElementById("menu").classList.toggle('hide');
	document.getElementById("focus").classList.toggle('zen');
	document.querySelector('article').classList.toggle('noborder');
}
