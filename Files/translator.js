let tessWorker;
let tessLang;
let paddleOCR;
let checkCloseByHeight = true;
async function initTess(lang){
    if (lang.indexOf("vert") != -1) {
        checkCloseByHeight = false;
    }else{
        checkCloseByHeight = true;
    }
    if (!tessWorker) {
        await loadLibrary("https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.min.js","text/javascript");
    }
    if (!tessLang || lang != tessLang) {
        tessLang = lang;
        worker = await Tesseract.createWorker(lang, 1, {
            logger: m => console.log(m),
        });
        if (lang.indexOf("vert") != -1) {
            await worker.setParameters({
                tessedit_pageseg_mode: Tesseract.PSM.SINGLE_BLOCK_VERT_TEXT,
            });
        }
        
    }
}

async function tessOCR(image) {
    const ret = await worker.recognize(image);
    let boxes = [];
    ret.data.lines.forEach(line => {
        if (line.confidence>10) {
            const box = {};
            box["text"] = line.text;
            box["target"] = "";
            box["geometry"] = {
                X: line.bbox.x0,
                Y: line.bbox.y0,
                width: line.bbox.x1 - line.bbox.x0,
                height: line.bbox.y1 - line.bbox.y0
            }
            boxes.push(box);
        }
    });
    const imgMap = {};
    boxes = mergedBoxes(boxes);
    imgMap["boxes"] = boxes;
    return imgMap;
}

async function initPaddleOCR(){
    checkCloseByHeight = true;
    if (!paddleOCR) {
        window.ortWasmPaths = "https://cdn.jsdelivr.net/npm/paddleocr-browser/dist/";
        await loadLibrary("https://cdn.jsdelivr.net/npm/paddleocr-browser/dist/paddleocr.js","text/javascript");
        let resourcesPath = "https://cdn.jsdelivr.net/npm/@gutenye/ocr-models/assets";
        paddleOCR = await Ocr.create({
            models: {
                detectionPath: resourcesPath+'/ch_PP-OCRv4_det_infer.onnx',
                recognitionPath: resourcesPath+'/ch_PP-OCRv4_rec_infer.onnx',
                dictionaryPath: resourcesPath+'/ppocr_keys_v1.txt'
            }
        })
    }
}

async function ocrWithPaddle(image){
    const results = await paddleOCR.detect(image);
    let boxes = [];
    results.forEach(result => {
        if (result.mean>0.5) {
            const box = {};
            box["text"] = result.text;
            box["target"] = "";
            box["geometry"] = {
                X: result.box[0][0],
                Y: result.box[0][1],
                width: result.box[1][0] - result.box[0][0],
                height: result.box[2][1] - result.box[0][1]
            }
            boxes.push(box);
        }
    });
    const imgMap = {};
    boxes = mergedBoxes(boxes);
    imgMap["boxes"] = boxes;
    return imgMap;
}

function loadLibrary(src,type,id,data){
    return new Promise(function (resolve, reject) {
        let scriptEle = document.createElement("script");
        scriptEle.setAttribute("type", type);
        scriptEle.setAttribute("src", src);
        if (id) {
             scriptEle.id = id;
        }
        if (data) {
            for (let key in data) {
                scriptEle.setAttribute(key, data[key]);
            }
        }
        document.body.appendChild(scriptEle);
        scriptEle.addEventListener("load", () => {
            console.log(src+" loaded")
            resolve(true);
        });
        scriptEle.addEventListener("error", (ev) => {
            console.log("Error on loading "+src, ev);
            reject(ev);
        });
    });
}

function clusterBoxes(boxes,baseBox) {
    let clustered = [];
    let merged = false;
    boxes.reverse();
    for (let index = boxes.length - 1; index >= 0; index--) {
        const box = boxes[index];
        if (areBoxesClose(baseBox,box)) {
            baseBox = mergedBoxesRect([baseBox,box])
            merged = true;
            boxes.splice(index, 1); //delete the box
        }
    }
    boxes.reverse();
    if (merged) {
        clustered.push(baseBox);
        return clustered;
    }else{
        return undefined;
    }
}


function mergedBoxes(boxes){
    let grouped = [];
    let mergedBoxes = [];
    while (boxes.length > 0) {
      let box = boxes.splice(0,1)[0];
      let clustered = clusterBoxes(boxes,box);
      if (clustered) {
        grouped.push(clustered);
      } else {
        grouped.push([box]); //single box as a group
      }
    }
    grouped.forEach(group => {
        let mergedBox = {};
        
        mergedBox = mergedBoxesRect(group);
        mergedBoxes.push(mergedBox);
    });
    return mergedBoxes;
}

async function translateBoxes(boxes) {
    for (let index = 0; index < boxes.length; index++) {
        let box = boxes[index]
        let text = box["text"];
        box["target"] = await translateUsingMyMemory(text);
    }
}

function textMerged(boxes) {
    let text = "";
    boxes.forEach(box => {
        text = text + box["text"] + "\n";
    });
    text = text.replace(/\n{1,}/g,"\n");
    return text;
}

function mergedBoxesRect(boxes){
    let merged = JSON.parse(JSON.stringify(boxes[0]));
    let minX = boxes[0]["geometry"]["X"];
    let minY = boxes[0]["geometry"]["Y"];
    let maxX = 0;
    let maxY = 0;
    boxes.forEach(box => {
        minX = Math.min(minX,box["geometry"]["X"]);
        minY = Math.min(minY,box["geometry"]["Y"]);
        maxX = Math.max(maxX,box["geometry"]["X"]+box["geometry"]["width"]);
        maxY = Math.max(maxY,box["geometry"]["Y"]+box["geometry"]["height"]);
    });
    merged["geometry"]["X"] = minX;
    merged["geometry"]["Y"] = minY;
    merged["geometry"]["width"] = maxX - minX;
    merged["geometry"]["height"] = maxY - minY;
    merged["text"] = textMerged(boxes);
    return merged;
}

function areBoxesClose(mergedBox,box2){
    if (checkCloseByHeight) {
        let box1Bottom = mergedBox["geometry"]["Y"] + mergedBox["geometry"]["height"];
        let box1Left = mergedBox["geometry"]["X"] + mergedBox["geometry"]["width"];
        let box1Right = mergedBox["geometry"]["X"] + mergedBox["geometry"]["width"];
        let box2Height = box2["geometry"]["height"];
        let box2Top = box2["geometry"]["Y"];
        let box2Left = box2["geometry"]["X"];
        let box2Right = box2["geometry"]["X"] + box2["geometry"]["width"];
        if (box1Bottom + box2Height * 3 - box2Top > 0) {
            if (box1Left > box2Left) {
                if (box1Right > box2Left) {
                    return true;
                }
            }else{
                if (box2Right > box1Left) {
                    return true;
                }
            }
        }
    }else{
        return true;
    }
    return false;
}

async function translateUsingMyMemory(source){
    try {
        
        let sourceLang = localStorage.getItem("sourceLang") ?? "ja";
        let targetLang = localStorage.getItem("targetLang") ?? "en";
        source = reflowText(sourceLang,source);
        let url = "https://api.mymemory.translated.net/get?";
        url = url + "q="+ encodeURIComponent(source);
        url = url + "&langpair=" + sourceLang + "|" + targetLang;
        let response = await fetch(url);
        let o = await response.json();
        return o.responseData.translatedText;
    } catch (error) {
        console.error(error);
        return "";
    }
}

function reflowText(sourceLang,source){
    if (sourceLang === "ja" || sourceLang === "zh") {
      return source.replace(/\n/g,"");
    }
    return source.replace(/\n/g," ");
}
