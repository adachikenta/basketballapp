/**
 * バスケットボール作戦板エディター
 */
// 定数定義
const COLORS = {
    court: '#FFFFFF',
    line: '#333333',
    player: '#0000FF',
    opponent: '#FF0000',
    arrow: '#333333',
    pass: '#FF6B00',
    text: '#333333',
    anchorPoint: '#FF00FF',
    handlePoint: '#00FFFF'
};
// 動き線用のパステルカラー
const PASTEL_COLORS = [
    '#FFB3BA',  // パステルピンク
    '#FFDFBA',  // パステルオレンジ
    '#FFFFBA',  // パステルイエロー
    '#BAFFC9',  // パステルグリーン
    '#BAE1FF',  // パステルブルー
    '#E0BBE4',  // パステルパープル
    '#FFD1DC',  // パステルローズ
    '#C7CEEA'   // パステルラベンダー
];
// コート表示設定
const COURT_CONFIG = {
    left: 30,     // [px] Canvasでの左マージン
    top: 30,    // [px] Canvasでの上マージン
    width: 900    // [px] コート表示幅（縦横比を保持して自動スケーリング）
};
const EDITOR_CONFIG = {
    maxCurvePoints: 5,
    playerRadius: 20,
    arrowWidth: 1,
    passArrowWidth: 3,
    anchorRadius: 2
};
// レイヤー管理クラス
class LayerManager {
    constructor(canvas) {
        this.canvas = canvas;
    }
    arrangeLayer(obj) {
        if (obj.isCourtElement) return; // コート要素は動かさない
        // コート要素の最大インデックスを取得
        const courtMaxIndex = this._getCourtMaxIndex();
        const targetIndex = courtMaxIndex + 1;
        // オブジェクトをコートより上に配置
        const currentIndex = this.canvas.getObjects().indexOf(obj);
        if (currentIndex < targetIndex) {
            obj.moveTo(targetIndex);
        }
        // アンカーポイントがあれば最前面へ
        if (obj.anchorObjects && obj.anchorObjects.length > 0) {
            setTimeout(() => {
                obj.anchorObjects.forEach(anchor => anchor.bringToFront());
                this.canvas.renderAll();
            }, 10);
        }
    }
    _getCourtMaxIndex() {
        const objects = this.canvas.getObjects();
        let maxIndex = -1;
        objects.forEach((obj, index) => {
            if (obj.isCourtElement) {
                maxIndex = Math.max(maxIndex, index);
            }
        });
        return maxIndex;
    }
    fixCourtBackground() {
        const objects = this.canvas.getObjects();
        const background = objects.find(obj => 
            obj.isCourtElement && obj.type === 'rect' && obj.fill === COLORS.court
        );
        if (background) {
            background.moveTo(0);
        }
    }
}
// 曲線生成ユーティリティ
class CurveGenerator {
    static generatePath(points) {
        if (points.length < 2) return '';
        let path = `M ${points[0].x} ${points[0].y}`;
        if (points.length === 2) {
            path += ` L ${points[1].x} ${points[1].y}`;
        } else if (points.length === 3) {
            path += ` Q ${points[1].x} ${points[1].y} ${points[2].x} ${points[2].y}`;
        } else {
            path += this._generateSmoothCurve(points.slice(1));
        }
        return path;
    }
    static _generateSmoothCurve(points) {
        let path = '';
        for (let i = 0; i < points.length - 2; i += 3) {
            const cp1 = points[i];
            const cp2 = points[Math.min(i + 1, points.length - 2)];
            const end = points[Math.min(i + 2, points.length - 1)];
            path += ` C ${cp1.x} ${cp1.y} ${cp2.x} ${cp2.y} ${end.x} ${end.y}`;
        }
        const remaining = points.length % 3;
        if (remaining === 1) {
            const last = points[points.length - 1];
            path += ` L ${last.x} ${last.y}`;
        } else if (remaining === 2) {
            const secondLast = points[points.length - 2];
            const last = points[points.length - 1];
            path += ` Q ${secondLast.x} ${secondLast.y} ${last.x} ${last.y}`;
        }
        return path;
    }
    static generateArrowHead(lastPoint, secondLastPoint, length = 15, angle = Math.PI / 6) {
        const direction = Math.atan2(
            lastPoint.y - secondLastPoint.y,
            lastPoint.x - secondLastPoint.x
        );
        return `M ${lastPoint.x} ${lastPoint.y} ` +
               `L ${lastPoint.x - length * Math.cos(direction - angle)} ` +
               `${lastPoint.y - length * Math.sin(direction - angle)} ` +
               `M ${lastPoint.x} ${lastPoint.y} ` +
               `L ${lastPoint.x - length * Math.cos(direction + angle)} ` +
               `${lastPoint.y - length * Math.sin(direction + angle)}`;
    }
}
// ツール処理の戦略パターン
class ToolStrategy {
    constructor(editor) {
        this.editor = editor;
    }
    onMouseDown(pointer) {}
    onMouseMove(pointer) {}
    onMouseUp(pointer) {}
    onActivate() {}
    onDeactivate() {}
}
class SelectTool extends ToolStrategy {
    onActivate() {
        this.editor.canvas.selection = true;
    }
}
class PlayerTool extends ToolStrategy {
    constructor(editor, color, isTeam) {
        super(editor);
        this.color = color;
        this.isTeam = isTeam;
    }
    onMouseDown(pointer) {
        const counter = this.isTeam ? 'teamPlayerCount' : 'opponentPlayerCount';
        const number = this.editor.state[counter]++;
        this.editor.objectFactory.createPlayer(pointer.x, pointer.y, number, this.color);
    }
}
class CurveArrowTool extends ToolStrategy {
    constructor(editor) {
        super(editor);
        this.points = [];
        this.tempLine = null;
    }
    onMouseDown(pointer) {
        this.points.push({x: pointer.x, y: pointer.y});
        if (this.points.length >= 2) {
            this._updateTempCurve();
        }
        if (this.points.length === EDITOR_CONFIG.maxCurvePoints) {
            this._finalize();
        }
    }
    onMouseMove(pointer) {
        if (this.points.length > 0 && this.points.length < EDITOR_CONFIG.maxCurvePoints) {
            this._updateTempCurve([...this.points, {x: pointer.x, y: pointer.y}]);
        }
    }
    _updateTempCurve(points = this.points) {
        if (this.tempLine) {
            this.editor.canvas.remove(this.tempLine);
        }
        const pathString = CurveGenerator.generatePath(points);
        const previewColor = PASTEL_COLORS[this.editor.state.currentArrowColorIndex];
        this.tempLine = new fabric.Path(pathString, {
            stroke: previewColor,
            strokeWidth: EDITOR_CONFIG.arrowWidth,
            strokeDashArray: [8, 4],
            fill: '',
            selectable: false,
            evented: false,
            opacity: 0.6
        });
        this.editor.canvas.add(this.tempLine);
        this.editor.canvas.renderAll();
    }
    _finalize() {
        if (this.tempLine) {
            this.editor.canvas.remove(this.tempLine);
            this.tempLine = null;
        }
        this.editor.objectFactory.createCurvedArrow(this.points);
        this.points = [];
        this.editor.canvas.renderAll();
    }
    onDeactivate() {
        if (this.tempLine) {
            this.editor.canvas.remove(this.tempLine);
            this.tempLine = null;
        }
        this.points = [];
    }
}
class PassArrowTool extends ToolStrategy {
    constructor(editor) {
        super(editor);
        this.startPoint = null;
        this.tempLine = null;
    }
    onMouseDown(pointer) {
        if (!this.startPoint) {
            this.startPoint = pointer;
        } else {
            this.editor.objectFactory.createPassArrow(
                this.startPoint.x, this.startPoint.y,
                pointer.x, pointer.y
            );
            this._reset();
        }
    }
    onMouseMove(pointer) {
        if (this.startPoint) {
            this._updateTempLine(pointer);
        }
    }
    _updateTempLine(pointer) {
        if (this.tempLine) {
            this.editor.canvas.remove(this.tempLine);
        }
        this.tempLine = new fabric.Line([
            this.startPoint.x, this.startPoint.y,
            pointer.x, pointer.y
        ], {
            stroke: COLORS.pass,
            strokeWidth: 2,
            strokeDashArray: [5, 5],
            selectable: false,
            evented: false,
            opacity: 0.5
        });
        this.editor.canvas.add(this.tempLine);
        this.editor.canvas.renderAll();
    }
    _reset() {
        this.startPoint = null;
        if (this.tempLine) {
            this.editor.canvas.remove(this.tempLine);
            this.tempLine = null;
        }
    }
    onDeactivate() {
        this._reset();
    }
}
class TextTool extends ToolStrategy {
    onMouseDown(pointer) {
        this.editor.objectFactory.createText(pointer.x, pointer.y);
    }
}
// オブジェクト生成ファクトリー
class ObjectFactory {
    constructor(editor) {
        this.editor = editor;
    }
    createPlayer(x, y, number, color) {
        const circle = new fabric.Circle({
            radius: EDITOR_CONFIG.playerRadius,
            fill: color,
            stroke: COLORS.line,
            strokeWidth: 2,
            originX: 'center',
            originY: 'center'
        });
        const text = new fabric.Text(number.toString(), {
            fontSize: 16,
            fill: COLORS.line,
            originX: 'center',
            originY: 'center'
        });
        const group = new fabric.Group([circle, text], {
            left: x,
            top: y,
            originX: 'center',
            originY: 'center'
        });
        this._addToCanvas(group);
        return group;
    }
    createCurvedArrow(points) {
        if (points.length < 2) return null;
        // パステルカラーを順番に使用
        const arrowColor = PASTEL_COLORS[this.editor.state.currentArrowColorIndex];
        this.editor.state.currentArrowColorIndex = 
            (this.editor.state.currentArrowColorIndex + 1) % PASTEL_COLORS.length;
        const pathString = CurveGenerator.generatePath(points);
        const curvePath = new fabric.Path(pathString, {
            stroke: arrowColor,
            strokeWidth: EDITOR_CONFIG.arrowWidth,
            fill: '',
            selectable: false,
            objectCaching: false,
            evented: false
        });
        const arrowHeadPath = CurveGenerator.generateArrowHead(
            points[points.length - 1],
            points[points.length - 2],
            20
        );
        const arrowHead = new fabric.Path(arrowHeadPath, {
            stroke: arrowColor,
            strokeWidth: EDITOR_CONFIG.arrowWidth,
            fill: '',
            selectable: false,
            objectCaching: false,
            evented: false
        });
        curvePath.set({
            curvePoints: points,
            isEditableCurve: true,
            arrowHeadPath: arrowHead
        });
        this._addToCanvas(curvePath);
        this.editor.canvas.add(arrowHead);
        const anchorObjects = this._createAnchors(points, curvePath);
        curvePath.anchorObjects = anchorObjects;
        anchorObjects.forEach(anchor => {
            this.editor.canvas.add(anchor);
            anchor.bringToFront();
        });
        this.editor.canvas.renderAll();
        return curvePath;
    }
    _createAnchors(points, curvePathObj) {
        const anchors = points.map((point, index) => {
            const isEndPoint = index === 0 || index === points.length - 1;
            const anchor = new fabric.Circle({
                left: point.x,
                top: point.y,
                radius: isEndPoint ? EDITOR_CONFIG.anchorRadius : 3,
                fill: isEndPoint ? COLORS.anchorPoint : COLORS.handlePoint,
                stroke: COLORS.line,
                strokeWidth: 1,
                originX: 'center',
                originY: 'center',
                hasControls: false,
                hasBorders: false,
                lockRotation: true,
                selectable: true,
                hoverCursor: 'move',
                pointIndex: index,
                isAnchor: true,
                curvePathObj: curvePathObj
            });
            anchor.on('moving', () => {
                this._updateCurvedArrow(curvePathObj);
            });
            return anchor;
        });
        return anchors;
    }
    _updateCurvedArrow(curvePathObj) {
        if (!curvePathObj.isEditableCurve) return;
        const newPoints = curvePathObj.anchorObjects.map(anchor => ({
            x: anchor.left,
            y: anchor.top
        }));
        const pathString = CurveGenerator.generatePath(newPoints);
        const arrowHeadPath = CurveGenerator.generateArrowHead(
            newPoints[newPoints.length - 1],
            newPoints[newPoints.length - 2],
            20
        );
        curvePathObj.set({ path: fabric.util.parsePath(pathString) });
        curvePathObj.arrowHeadPath.set({ path: fabric.util.parsePath(arrowHeadPath) });
        curvePathObj.curvePoints = newPoints;
        curvePathObj.setCoords();
        curvePathObj.arrowHeadPath.setCoords();
        curvePathObj.anchorObjects.forEach(anchor => anchor.bringToFront());
        this.editor.canvas.renderAll();
    }
    _updateGroupBounds(group) {
        try {
            const objects = group.getObjects();
            objects.forEach(obj => {
                if (obj.setCoords) obj.setCoords();
            });
            if (group._calcBounds) group._calcBounds();
            if (group._updateObjectsCoords) group._updateObjectsCoords();
            group.setCoords();
            group.set({ dirty: true });
        } catch (e) {
            group.setCoords();
        }
    }
    createPassArrow(x1, y1, x2, y2) {
        const line = new fabric.Line([x1, y1, x2, y2], {
            stroke: COLORS.pass,
            strokeWidth: EDITOR_CONFIG.passArrowWidth,
            strokeDashArray: [10, 5],
            selectable: false
        });
        const angle = Math.atan2(y2 - y1, x2 - x1);
        const arrowHead = new fabric.Triangle({
            left: x2,
            top: y2,
            width: 15,
            height: 20,
            fill: COLORS.pass,
            stroke: COLORS.pass,
            strokeWidth: 1,
            angle: (angle * 180 / Math.PI) + 90,
            originX: 'center',
            originY: 'center',
            selectable: false
        });
        const passArrow = new fabric.Group([line, arrowHead], {
            selectable: true
        });
        this._addToCanvas(passArrow);
        return passArrow;
    }
    createText(x, y) {
        const text = new fabric.IText('テキスト', {
            left: x,
            top: y,
            fontSize: 16,
            fill: COLORS.text,
            fontFamily: 'Arial'
        });
        this._addToCanvas(text);
        this.editor.canvas.setActiveObject(text);
        return text;
    }
    _addToCanvas(obj) {
        this.editor.canvas.add(obj);
        this.editor.layerManager.arrangeLayer(obj);
        this.editor.canvas.renderAll();
    }
}
// コート描画クラス（画像ベース）
class CourtDrawer {
    constructor(canvas) {
        this.canvas = canvas;
    }
    draw() {
        // court.png画像を読み込んで背景として設定
        fabric.Image.fromURL('/static/img/court.png', (img) => {
            // 縦横比を保持したまま、指定された幅に合わせてスケーリング
            const scale = COURT_CONFIG.width / img.width;
            const scaledHeight = img.height * scale;
            
            // Canvasサイズを画像に合わせて調整
            this.canvas.setDimensions({
                width: COURT_CONFIG.left + COURT_CONFIG.width + COURT_CONFIG.left,
                height: COURT_CONFIG.top + scaledHeight + COURT_CONFIG.top
            });
            
            img.set({
                left: COURT_CONFIG.left,
                top: COURT_CONFIG.top,
                scaleX: scale,
                scaleY: scale,  // 同じスケール値を使用して縦横比を維持
                selectable: false,
                evented: false,
                isCourtElement: true,
                isCourtBackground: true
            });
            this.canvas.add(img);
            img.sendToBack();
            this.canvas.renderAll();
        });
    }
}
// メインエディタークラス
class BasketballCourtEditor {
    constructor(canvasId) {
        this.canvas = new fabric.Canvas(canvasId, {
            backgroundColor: COLORS.court,
            selection: true
        });
        this.state = {
            currentMode: 'select',
            teamPlayerCount: 1,
            opponentPlayerCount: 1,
            currentArrowColorIndex: 0
        };
        this.layerManager = new LayerManager(this.canvas);
        this.objectFactory = new ObjectFactory(this);
        this.courtDrawer = new CourtDrawer(this.canvas);
        this.tools = {
            select: new SelectTool(this),
            player: new PlayerTool(this, COLORS.player, true),
            opponent: new PlayerTool(this, COLORS.opponent, false),
            arrow: new CurveArrowTool(this),
            pass: new PassArrowTool(this),
            text: new TextTool(this)
        };
        this._initialize();
    }
    _initialize() {
        this.courtDrawer.draw();
        this._setupEventHandlers();
    }
    _setupEventHandlers() {
        this.canvas.on('mouse:down', (e) => this._handleMouseDown(e));
        this.canvas.on('mouse:move', (e) => this._handleMouseMove(e));
        this.canvas.on('mouse:up', (e) => this._handleMouseUp(e));
    }
    _handleMouseDown(e) {
        // 既存のオブジェクトがクリックされた場合は、ツールの処理をスキップ
        if (e.target && !e.target.isCourtElement) {
            return;
        }
        const pointer = this.canvas.getPointer(e.e);
        const tool = this.tools[this.state.currentMode];
        if (tool && tool.onMouseDown) {
            tool.onMouseDown(pointer);
        }
    }
    _handleMouseMove(e) {
        const pointer = this.canvas.getPointer(e.e);
        const tool = this.tools[this.state.currentMode];
        if (tool && tool.onMouseMove) {
            tool.onMouseMove(pointer);
        }
    }
    _handleMouseUp(e) {
        const pointer = this.canvas.getPointer(e.e);
        const tool = this.tools[this.state.currentMode];
        if (tool && tool.onMouseUp) {
            tool.onMouseUp(pointer);
        }
    }
    setMode(mode) {
        const currentTool = this.tools[this.state.currentMode];
        if (currentTool && currentTool.onDeactivate) {
            currentTool.onDeactivate();
        }
        this.state.currentMode = mode;
        const newTool = this.tools[mode];
        if (newTool && newTool.onActivate) {
            newTool.onActivate();
        }
        this._updateButtonStates(mode);
        this.canvas.renderAll();
    }
    _updateButtonStates(activeMode) {
        const buttons = document.querySelectorAll('.tool-button');
        buttons.forEach(button => {
            const onclickAttr = button.getAttribute('onclick');
            if (onclickAttr && onclickAttr.includes(`setMode('${activeMode}')`)) {
                button.classList.add('active');
            } else if (onclickAttr && onclickAttr.includes('setMode(')) {
                button.classList.remove('active');
            }
        });
    }
    deleteSelected() {
        const activeObjects = this.canvas.getActiveObjects();
        activeObjects.forEach(obj => {
            if (obj.isAnchor && obj.curvePathObj) {
                this._deleteCurvedArrow(obj.curvePathObj);
            } else if (obj.isEditableCurve) {
                this._deleteCurvedArrow(obj);
            } else {
                this.canvas.remove(obj);
            }
        });
        this.canvas.discardActiveObject();
        this.canvas.renderAll();
    }
    _deleteCurvedArrow(curvePathObj) {
        if (curvePathObj.anchorObjects) {
            curvePathObj.anchorObjects.forEach(anchor => {
                this.canvas.remove(anchor);
            });
        }
        if (curvePathObj.arrowHeadPath) {
            this.canvas.remove(curvePathObj.arrowHeadPath);
        }
        this.canvas.remove(curvePathObj);
    }
    clearCanvas() {
        const objects = this.canvas.getObjects().slice();
        objects.forEach(obj => {
            if (!obj.isCourtElement) {
                if (obj.isEditableCurve) {
                    if (obj.anchorObjects) {
                        obj.anchorObjects.forEach(anchor => this.canvas.remove(anchor));
                    }
                    if (obj.arrowHeadPath) {
                        this.canvas.remove(obj.arrowHeadPath);
                    }
                }
                this.canvas.remove(obj);
            }
        });
        this.state.teamPlayerCount = 1;
        this.state.opponentPlayerCount = 1;
        this.state.currentArrowColorIndex = 0;
        this.canvas.renderAll();
    }
    saveToJSON() {
        return this.canvas.toJSON(['curvePoints', 'isEditableCurve', 'isCourtElement', 'arrowHeadPath']);
    }
    loadFromJSON(json, callback) {
        this.canvas.loadFromJSON(json, () => {
            this._rebuildAnchors();
            this.canvas.renderAll();
            if (callback) callback();
        });
    }
    _rebuildAnchors() {
        const objects = this.canvas.getObjects();
        const curvePathObjects = objects.filter(obj => obj.isEditableCurve && obj.curvePoints);
        
        curvePathObjects.forEach(curvePathObj => {
            const arrowHeadIndex = curvePathObj.arrowHeadPath;
            if (typeof arrowHeadIndex === 'number') {
                curvePathObj.arrowHeadPath = objects[arrowHeadIndex];
            } else if (!curvePathObj.arrowHeadPath || !curvePathObj.arrowHeadPath.path) {
                const arrowHeadPath = CurveGenerator.generateArrowHead(
                    curvePathObj.curvePoints[curvePathObj.curvePoints.length - 1],
                    curvePathObj.curvePoints[curvePathObj.curvePoints.length - 2]
                );
                const arrowHead = new fabric.Path(arrowHeadPath, {
                    stroke: COLORS.arrow,
                    strokeWidth: EDITOR_CONFIG.arrowWidth,
                    fill: '',
                    selectable: false,
                    objectCaching: false,
                    evented: false
                });
                this.canvas.add(arrowHead);
                curvePathObj.arrowHeadPath = arrowHead;
            }
            
            const anchors = this.objectFactory._createAnchors(curvePathObj.curvePoints, curvePathObj);
            curvePathObj.anchorObjects = anchors;
            anchors.forEach(anchor => {
                this.canvas.add(anchor);
                anchor.bringToFront();
            });
        });
    }
}
// グローバルインターフェース
let editor = null;
function initCanvas() {
    editor = new BasketballCourtEditor('court-canvas');
}
function setMode(mode) {
    if (editor) editor.setMode(mode);
}
function deleteSelected() {
    if (editor) editor.deleteSelected();
}
function clearCanvas() {
    if (editor) editor.clearCanvas();
}
function saveDiagram() {
    if (!editor) return;
    const diagramName = document.getElementById('diagram-name').value.trim();
    if (!diagramName) {
        alert('プレー名を入力してください');
        return;
    }
    const description = document.getElementById('diagram-description').value.trim();
    const jsonData = editor.saveToJSON();
    fetch('/api/play/save', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            name: diagramName,
            description: description,
            diagram_data: JSON.stringify(jsonData)
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'success') {
            alert('保存しました！');
            document.getElementById('diagram-id').value = data.id;
        } else {
            alert('保存に失敗しました: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('保存に失敗しました');
    });
}
function loadDiagram(diagramId) {
    if (!editor) return;
    fetch(`/api/play/${diagramId}`)
    .then(response => response.json())
    .then(data => {
        if (data.diagram_data) {
            editor.loadFromJSON(data.diagram_data, () => {
                document.getElementById('diagram-name').value = data.name || '';
                document.getElementById('diagram-description').value = data.description || '';
                document.getElementById('diagram-id').value = data.id;
            });
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('読み込みに失敗しました');
    });
}
document.addEventListener('DOMContentLoaded', function() {
    initCanvas();
    const urlParams = new URLSearchParams(window.location.search);
    const diagramId = urlParams.get('id');
    if (diagramId) {
        loadDiagram(diagramId);
    }
});
