import QtQuick
import QtQuick.Window

// Draw an original background at the window's resolution; idle dashboards do not repaint.
Canvas {
    id: canvas
    property real phase: 0
    property int styleMode: 1
    onPhaseChanged: requestPaint()
    onStyleModeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    FrameAnimation {
        running: canvas.visible && canvas.styleMode === 0 && canvas.Window.window && canvas.Window.window.active
        property real elapsed: 0
        onTriggered: {
            elapsed += frameTime
            if (elapsed < 0.09) return
            canvas.phase = (canvas.phase + elapsed * 0.21) % (Math.PI*2)
            elapsed = 0
        }
    }
    onPaint: {
        const ctx = getContext("2d")
        const w = width, h = height
        if (w <= 0 || h <= 0) return
        const bg = ctx.createLinearGradient(w*0.25, 0, w*0.7, h)
        bg.addColorStop(0, "#202a40")
        bg.addColorStop(0.5, "#131d30")
        bg.addColorStop(1, "#090d15")
        ctx.fillStyle = bg
        ctx.fillRect(0, 0, w, h)
        if (styleMode === 2) return
        for (let i = 0; i < 52; ++i) {
            const x = ((i * 173 + 39) % 997) / 997, y = ((i * 229 + 13) % 991) / 991
            ctx.fillStyle = Qt.rgba(0.72, 0.84, 1, 0.09 + (i%5)*0.035)
            ctx.fillRect(x*w, y*h, i%6 === 0 ? 2 : 1, 1.3)
        }
        const p = styleMode === 0 ? phase : 0
        for (let i = 0; i < 35; ++i) {
            const n = i / 34
            ctx.beginPath()
            ctx.strokeStyle = Qt.rgba(0.52, 0.67, 0.94, 0.09 + Math.sin(n*Math.PI)*0.16)
            ctx.lineWidth = 1
            for (let x = 0; x <= w + 8; x += 8) {
                const u = x/w
                const wave = Math.sin(u * 7.2 + p + n*2.8) * (0.025 + 0.052*u)
                           + Math.cos(u * 11.1 - p + n*1.8)*0.03
                const y = h*(0.60 + wave + n*0.075)
                if (x === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.stroke()
        }
    }
}
