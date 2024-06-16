function m(id) {
	closeMenus(id);
	document.getElementById(id).classList.toggle("drop");
	document.getElementById(id+"Menu").classList.toggle("show");
}
function closeMenus(notId) {
	var m = document.getElementsByClassName("submenu");
	for (i = 0; i < m.length; i++) {
		if (m[i].id == notId+"Menu")
			continue
		m[i].classList.remove('show');
	}
	var m = document.getElementsByClassName("menuButton");
	for (i = 0; i < m.length; i++) {
		if (m[i].id == notId)
			continue
		m[i].classList.remove('drop');
	}
}
function zen() {
	document.getElementById("bird").classList.toggle('hide');
	document.getElementById("toc").classList.toggle('hide');
	document.getElementById("menu").classList.toggle('hide');
	document.getElementById("focus").classList.toggle('zen');
	document.querySelector('article').classList.toggle('noborder');
}
window.onclick = function(e) { if (!e.target.matches('.menuButton')) closeMenus() }
