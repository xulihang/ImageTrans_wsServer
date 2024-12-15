var synth = window.speechSynthesis;
var voices = [];

function loadVoices(){
    voices = [];
    var allVoices = synth.getVoices();
    for(i = 0; i < allVoices.length ; i++) {
        voices.push(allVoices[i]);
    }
}

function populateVoiceList(targetSelect) {
    var selectedIndex = targetSelect.selectedIndex < 0 ? 0 : targetSelect.selectedIndex;
    targetSelect.innerHTML = '';
    for(i = 0; i < voices.length ; i++) {
      var option = document.createElement('option');
      option.textContent = voices[i].name + ' (' + voices[i].lang + ')';
      option.setAttribute('data-lang', voices[i].lang);
      option.setAttribute('data-name', voices[i].name);
      targetSelect.appendChild(option);
    }
    targetSelect.selectedIndex = selectedIndex;
}

function speak(text, voice){
    if (synth.speaking) {
        console.error('speechSynthesis.speaking');
        return;
    }
    if (text !== '') {
        var utterThis = new SpeechSynthesisUtterance(text);
        utterThis.onend = function () {
            console.log('SpeechSynthesisUtterance.onend');
        }
        utterThis.onerror = function () {
            console.error('SpeechSynthesisUtterance.onerror');
        }
        if (voice) {
            utterThis.voice = voice;
        }
        synth.speak(utterThis);
    }
}

function getVoiceByName(name){
    for(i = 0; i < voices.length ; i++) {
       if (voices[i].name === name) {
        return voices[i];
       }
    }
}
