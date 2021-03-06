package love2d.utils;
import dust.Dust;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Graphics;
import flash.display.JointStyle;
import flash.display.Sprite;
import flash.display.StageQuality;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.Lib;
import flash.system.Capabilities;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import love2d.Handler;
import love2d.Handler.Color;
import love2d.Love;
import openfl.Assets;

/**
 * Drawing of shapes and images, management of screen geometry.
 */

class LoveGraphics
{
	
	private var _sprite:Sprite;
	private var _bm:Bitmap;
	@:allow(love2d) private var _mat:Matrix;
	private var _blendMode:BlendMode;
	private var _colorTransform:ColorTransform;
	private var _font:Font;
	private var _bufferRect:Rectangle;
	private var _textField:TextField;
	private var _textFormat:TextFormat;
	private var _pointSize:Float = 1;
	private var _lineWidth:Float = 1;
	private var _jointStyle:JointStyle;
	private var _lineStyle:String;
	private var _canvas:Canvas;
	private var _color:Color;
	
	private var _featuresMap:Map<String, Bool>;
	
	@:allow(love2d) private var gr:Graphics;
	
	@:allow(love2d) private var _dust:Dust;
	
	// params
	private var _angle:Float;
	private var _scaleX:Float;
	private var _scaleY:Float;
	private var _kx:Float;
	private var _ky:Float;
	private var _dx:Float;
	private var _dy:Float;
	
	public function new() 
	{
		_sprite = new Sprite();
		gr = _sprite.graphics;
		
		// dust
		_dust = new Dust();
		_dust.active = false;
		_dust.targetGraphics = gr;
		_dust.errorCallback = Love.newError;
		
		_bm = new Bitmap();
		_mat = new Matrix();
		_jointStyle = JointStyle.ROUND;
		_bufferRect = new Rectangle();
		_colorTransform = new ColorTransform();
		_textFormat = new TextFormat();
		_canvas = null;
		
		_textField = new TextField();
		_textField.text = "";
		_textField.defaultTextFormat = _textFormat;
		_textField.embedFonts = false;
		_textField.selectable = false;
		_textField.visible = true;
		_textField.autoSize = TextFieldAutoSize.LEFT;
		
		_sprite.addChild(_bm);
		Lib.current.stage.addChild(_sprite);
		
		// graphics features
		_featuresMap = new Map();
		_featuresMap.set("canvas", false);
		_featuresMap.set("npot", true);
		_featuresMap.set("subtractive", true);
		_featuresMap.set("shader", false);
		_featuresMap.set("hdrcanvas", false);
		_featuresMap.set("multicanvas", false);
		_featuresMap.set("mipmap", false);
		_featuresMap.set("dxt", false);
		_featuresMap.set("bc5", false);
		
		_lineStyle = "smooth";
	}
	
	/**
	 * Resets the current coordinate transformation. 
	 */
	inline public function origin() {
		_angle = 0;
		_scaleX = 1; _scaleY = 1;
		_kx = 0; _ky = 0;
		_dx = 0; _dy = 0;
	}
	
	/**
	 * Translates the coordinate system in two dimensions. 
	 * @param	dx	The translation relative to the x-axis. 
	 * @param	dy	The translation relative to the y-axis. 
	 */
	inline public function translate(dx:Float, dy:Float) {
		_dx = dx; _dy = dy;
	}
	
	/**
	 * Rotates the coordinate system in two dimensions. 
	 * @param	angle	The amount to rotate the coordinate system in radians. 
	 */
	inline public function rotate(angle:Float) {
		_angle = angle;
	}
	
	/**
	 * Scales the coordinate system in two dimensions. 
	 * @param	sx	The scaling in the direction of the x-axis. 
	 * @param	sy	The scaling in the direction of the y-axis. If omitted, it defaults to same as parameter sx. 
	 */
	inline public function scale(sx:Float, sy:Float) {
		_scaleX = sx; _scaleY = sy;
	}
	
	/**
	 * Shears the coordinate system. 
	 * @param	kx	The shear factor on the x-axis. 
	 * @param	ky	The shear factor on the y-axis. 
	 */
	inline public function shear(kx:Float, ky:Float) {
		_kx = kx; _ky = ky;
	}
	
	/**
	 * Copies and pushes the current coordinate transformation to the transformation stack. 
	 */
	public function push() {
	}
	
	/**
	 * Pops the current coordinate transformation from the transformation stack. 
	 */
	public function pop() {
	}
	
	/**
	 * Clears the screen to the background color and restores the default coordinate system. 
	 */
	inline public function clear() {
		gr.clear();
		
		var c:BitmapData;
		if (_canvas == null) c = Love.handler.canvas;
		else c = _canvas._bitmapData;
		
		c.fillRect(c.rect, 0xFF000000 | Love.handler.intBgColor);
	}
	
	/**
	 * Resets the current graphics settings.
	 * Calling reset makes the current drawing color white, the current background color black,
	 * resets any active Canvas or PixelEffect, and removes any scissor settings.
	 * It sets the BlendMode to alpha and ColorMode to modulate.
	 * It also sets both the point and line drawing modes to smooth and their sizes to 1.0. 
	 */
	public function reset() {
		/*setColor();
		setBackgroundColor(0, 0, 0, 255);
		setBlendMode("alpha");
		_pointSize = _lineWidth = 1;
		_lineStyle = "smooth";*/
	}
	
	/**
	 * Sets the color used for drawing. 
	 * @param	?red	The amount of red. 
	 * @param	?green	The amount of green. 
	 * @param	?blue	The amount of blue. 
	 * @param	?alpha	The amount of alpha. The alpha value will be applied to all subsequent draw operations, even the drawing of an image. 
	 */
	inline public function setColor(?red:Dynamic = 255, ?green:Int = 255, ?blue:Int = 255, ?alpha:Int = 255) {
		var r:Int = 0; if (Std.is(red, Int)) {
			r = if (red < 0) 0 else if (red > 255) 255 else red;
		}
		green = if (green < 0) 0 else if (green > 255) 255 else green;
		blue = if (blue < 0) 0 else if (blue > 255) 255 else blue;
		alpha = if (alpha < 0) 0 else if (alpha > 255) 255 else alpha;
		/*if (Std.is(red, Array)) {
			var l:Int = red.length;
			r = if (l > 0) red[0] else 255;
			green = if (l > 1) red[1] else 255;
			blue = if (l > 2) red[2] else 255;
			alpha = if (l > 3) red[3] else 255;
		}*/
		Love.handler.color = {r: r, g: green, b: blue, a: alpha};
		_colorTransform.redMultiplier = red / 255;
		_colorTransform.greenMultiplier = green / 255;
		_colorTransform.blueMultiplier = blue / 255;
		_colorTransform.alphaMultiplier = alpha / 255;
	}
	
	/**
	 * Gets the current color. 
	 * @return	The table that contains the current color.
	 */
	inline public function getColor():Color {
		return Love.handler.color;
	}
	
	/**
	 * Sets the background color.
	 * @param	?red	The red component (0-255). 
	 * @param	?green	The green component (0-255). 
	 * @param	?blue	The blue component (0-255). 
	 * @param	?alpha	The alpha component (0-255). 
	 */
	inline public function setBackgroundColor(?red:Int = 255, ?green:Int = 255, ?blue:Int = 255, ?alpha:Int = 255) {
		red = if (red < 0) 0 else if (red > 255) 255 else red;
		green = if (green < 0) 0 else if (green > 255) 255 else green;
		blue = if (blue < 0) 0 else if (blue > 255) 255 else blue;
		alpha = if (alpha < 0) 0 else if (alpha > 255) 255 else alpha;
		Love.handler.bgColor = {r: red, g: green, b: blue, a: alpha};
	}
	
	/**
	 * Gets the current background color. 
	 * @return	The table that contains the current background color.
	 */
	inline public function getBackgroundColor():Color {
		return Love.handler.bgColor;
	}
	
	/**
	 * Sets the line width. 
	 * @param	width	The width of the line. 
	 */
	inline public function setLineWidth(width:Float) {
		_lineWidth = width;
	}
	
	/**
	 * Gets the current line width. 
	 * @return	The current line width. 
	 */
	inline public function getLineWidth():Float {
		return _lineWidth;
	}
	
	/**
	 * Sets the line join style. 
	 * @param	join	The LineJoin to use. 
	 */
	public function setLineJoin(join:String) {
		switch(join) {
			case "none": _jointStyle = JointStyle.ROUND;
			case "miter": _jointStyle = JointStyle.MITER;
			case "bevel": _jointStyle = JointStyle.BEVEL;
			default: return;
		}
	}
	
	/**
	 * Gets the line join style. 
	 * @return	The LineJoin style. 
	 */
	public function getLineJoin():String {
		switch(_jointStyle) {
			case JointStyle.ROUND: return "none";
			case JointStyle.MITER: return "miter";
			case JointStyle.BEVEL: return "bevel";
		}
		return "";
	}
	
	/**
	 * Sets the point size. 
	 * @param	size	The new point size. 
	 */
	inline public function setPointSize(size:Float) {
		_pointSize = size;
	}
	
	/**
	 * Gets the point size. 
	 * @return	The current point size. 
	 */
	inline public function getPointSize():Float {
		return _pointSize;
	}
	
	/**
	 * Sets the line style. 
	 * @param	style	The LineStyle to use. 
	 */
	inline public function setLineStyle(style:String) {
		_lineStyle = style;
	}
	
	/**
	 * Gets the line style. 
	 * @return	The current line style. 
	 */
	inline public function getLineStyle():String {
		return _lineStyle;
	}
	
	/**
	 * Gets the width in pixels of the window. 
	 * @return	The width of the window. 
	 */
	inline public function getWidth():Int {
		return Std.int(Capabilities.screenResolutionX);
	}
	
	/**
	 * Gets the height in pixels of the window. 
	 * @return	The height of the window. 
	 */
	inline public function getHeight():Int {
		return Std.int(Capabilities.screenResolutionY);
	}
	
	/**
	 * Gets the width and height of the window. 
	 * @return	The width and height of the window. 
	 */
	inline public function getDimensions():Size {
		return Love.window.getDimensions();
	}
	
	/**
	 * Sets the render target to a specified Canvas.
	 * All drawing operations until the next love.graphics.setCanvas call
	 * will be redirected to the Canvas and not shown on the screen. 
	 * @param	?canvas	The new target. 
	 */
	inline public function setCanvas(?canvas:Canvas = null) {
		_canvas = canvas;
	}
	
	/**
	 * Gets the current target Canvas. 
	 * @return	The Canvas set by setCanvas. Returns null if drawing to the real screen. 
	 */
	inline public function getCanvas():Canvas {
		return _canvas;
	}
	
	/**
	 * Set an already-loaded Font as the current font or create and load a new one from the file and size. 
	 * @param	font	The Font object to use. 
	 */
	public function setFont(?font:Font = null) {
		_font = font;
		if (font != null) {
			_textField.embedFonts = true;
			_textFormat.font = _font._flashFont.fontName;
			_textFormat.size = _font._size;
		}
		else _textField.embedFonts = false;
		_textField.defaultTextFormat = _textFormat;
		#if !flash
		_textField.setTextFormat(_textFormat, 0, _textField.text.length);
		#else
		_textField.setTextFormat(_textFormat);
		#end
	}
	
	/**
	 * Gets the current Font object. 
	 * @return	The current Font.
	 */
	inline public function getFont():Font {
		return _font;
	}
	
	/**
	 * Creates and sets a new Font. 
	 * @param	data	The path and name of the file with the font. 
	 * @param	?size = 12	The new font. 
	 * @return
	 */
	inline public function setNewFont(data:Dynamic, ?size = 12):Font {
		var f:Font = newFont(data, size);
		setFont(f);
		return f;
	}
	
	/**
	 * Sets the blending mode. 
	 * @param	?mode	The blend mode to use. 
	 */
	public function setBlendMode(?mode:String = "alpha") {
		switch(mode) {
			case "additive": _blendMode = BlendMode.ADD;
			case "alpha": _blendMode = BlendMode.ALPHA;
			case "subtractive": _blendMode = BlendMode.SUBTRACT;
			case "multiplicative": _blendMode = BlendMode.MULTIPLY;
		}
	}
	
	/**
	 * Gets the blending mode. 
	 * @return	The current blend mode. 
	 */
	public function getBlendMode():String {
		switch(_blendMode) {
			case BlendMode.ADD: return "additive";
			case BlendMode.ALPHA, BlendMode.NORMAL: return "alpha";
			case BlendMode.SUBTRACT: return "subtractive";
			case BlendMode.MULTIPLY: return "multiplicative";
			default: return "";
		}
		return "";
	}
	
	/**
	 * Checks if certain graphics functions can be used. 
	 * @param	feature		The graphics feature to check for. 
	 * @return	True if feature is supported, false otherwise. 
	 */
	public function isSupported(feature:String):Bool {
		if (!_featuresMap.exists(feature)) {
			Love.newError("Wrong graphics feature.");
			return false;
		}
		return _featuresMap.get(feature);
	}
	
	/**
	 * Draws a rectangle. 
	 * @param	mode	How to draw the rectangle. 
	 * @param	x	The position of top-left corner along x-axis. 
	 * @param	y	The position of top-left corner along y-axis. 
	 * @param	width	Width of the rectangle. 
	 * @param	height	Height of the rectangle. 
	 */
	public function rectangle(mode:String, x:Float, y:Float, width:Float, height:Float) {
		gr.clear();
		// updateBatch();
		if (mode == "line") {
			//gr.lineStyle(_lineWidth, Love.handler.intColor, Love.handler.color.a / 255);
			//gr.drawRect(x, y, width, height);
		}
		else if (mode == "fill")
		{
			gr.beginFill(Love.handler.intColor, Love.handler.color.a / 255);
			gr.drawRect(x, y, width, height);
			gr.endFill();
		}
		
		/*var rt:BitmapData;
		if (_canvas == null) rt = Love.handler.canvas;
		else rt = _canvas._bitmapData;
		//
		rt.draw(_sprite);*/
	}
	
	/**
	 * Draws a circle. 
	 * @param	mode	How to draw the circle. 
	 * @param	x	The position of the center along x-axis. 
	 * @param	y	The position of the center along y-axis. 
	 * @param	radius	The radius of the circle. 
	 * @param	?segments	The number of segments used for drawing the circle. 
	 */
	public function circle(mode:String, x:Float, y:Float, radius:Float, ?segments:Int) {
		gr.clear();
		
		// TO-DO: line style
		Lib.trace("x: " + x + ", " + y);
		if (mode == "line") {
			gr.lineStyle(_lineWidth, Love.handler.intColor, Love.handler.color.a / 255);
			gr.drawCircle(x, y, radius);
		}
		else if (mode == "fill")
		{
			gr.beginFill(Love.handler.intColor, Love.handler.color.a / 255);
			//gr.drawCircle(x * 2, y * 2, radius);
			gr.endFill();
		}
		
		/*var rt:BitmapData;
		if (_canvas == null) rt = Love.handler.canvas;
		else rt = _canvas._bitmapData;
		//
		rt.draw(_sprite);*/
		// updateBatch();
	}
	
	/**
	 * Draws a point. 
	 * @param	x	The position on the x-axis. 
	 * @param	y	The position on the y-axis. 
	 */
	public function point(x:Float, y:Float) {
		rectangle("fill", x, y, getPointSize(), getPointSize());
	}
	
	/**
	 * Draws lines between points. 
	 * @param	x1	The position of first point on the x-axis. 
	 * @param	?y1	The position of first point on the y-axis. 
	 * @param	?x2	The position of second point on the x-axis. 
	 * @param	?y2	The position of second point on the y-axis. 
	 */
	public function line(x1:Dynamic, ?y1:Float = null, ?x2:Float = null, ?y2:Float = null) {
		if (Std.is(x1, Float)) {
			
		}
		else if (Std.is(x1, Array)) {
			if (x1.length == 0) {
				Love.newError("The given array is invalid.");
				return;
			}
			if (x1.length % 2 != 0) x1.pop();
		}
		gr.clear();
		
		if (_lineStyle == "smooth") Love.stage.quality = StageQuality.BEST;
		else if (_lineStyle == "rough") Love.stage.quality = StageQuality.LOW;
		
		gr.lineStyle(_lineWidth, Love.handler.intColor, Love.handler.color.a / 255);
		if (Std.is(x1, Float)) {
			gr.moveTo(x2, y2);
			gr.lineTo(x1, y1);
			Lib.trace("lineTo");
		}
		else if (Std.is(x1, Array)) {
			/*var i:Int, o:Array<Float> = cast x1;
			i = 2; while (i < o.length) {
				gr.moveTo(o[i - 2], o[i - 1]);
				gr.lineTo(o[i], o[i + 1]);
				i += 2;
			}*/
		}
		
		var rt:BitmapData;
		if (_canvas == null) rt = Love.handler.canvas;
		else rt = _canvas._bitmapData;
		//
		rt.draw(_sprite);
		
		gr.lineStyle();
		// updateBatch();
	}
	
	/**
	 * Draws an arc. 
	 * @param	mode	How to draw the arc. 
	 * @param	x	The position of the center along x-axis. 
	 * @param	y	The position of the center along y-axis. 
	 * @param	radius	Radius of the arc. 
	 * @param	angle1	The angle at which the arc begins. 
	 * @param	angle2	The angle at which the arc terminates. 
	 * @param	?segments	The number of segments used for drawing the arc. 
	 */
	public function arc(mode:String, x:Float, y:Float, radius:Float, angle1:Float, angle2:Float, ?segments:Float = 10) {
	}
	
	/**
	 * Draw a polygon. 
	 * @param	mode	How to draw the polygon. 
	 * @param	vertices	The vertices of the polygon as a table. 
	 */
	public function polygon(mode:String, vertices:Array<Handler.Point>) {
		gr.clear();
		
		if (_lineStyle == "smooth") Love.stage.quality = StageQuality.BEST;
		else if (_lineStyle == "rough") Love.stage.quality = StageQuality.LOW;
		
		if (mode == "fill") {
			gr.beginFill(Love.handler.intColor, Love.handler.color.a / 255);
		}
		else if (mode == "line")
		{
			gr.lineStyle(_lineWidth, Love.handler.intColor, Love.handler.color.a / 255);
		}
		gr.moveTo(vertices[0].x, vertices[0].y);
		for (i in 1...vertices.length) gr.lineTo(vertices[i].x, vertices[i].y);
		gr.lineTo(vertices[0].x, vertices[0].y);
		gr.endFill();
		
		var rt:BitmapData;
		if (_canvas == null) rt = Love.handler.canvas;
		else rt = _canvas._bitmapData;
		
		rt.draw(_sprite);
		
		gr.lineStyle();
		// updateBatch();
	}
	
	/**
	 * Draws a Drawable object (an Image, Canvas, SpriteBatch, ParticleSystem, or Mesh) on the screen with optional rotation, scaling and shearing. 
	 * @param	drawable	A drawable object. 
	 * @param	?x	The position to draw the object (x-axis). 
	 * @param	?y	The position to draw the object (y-axis). 
	 * @param	?r	Orientation (radians). 
	 * @param	?sx	Scale factor (x-axis). 
	 * @param	?sy	Scale factor (y-axis). 
	 * @param	?ox	Origin offset (x-axis). 
	 * @param	?oy	Origin offset (y-axis).
	 * @param	?kx Shearing factor (x-axis). 
	 * @param	?ky Shearing factor (y-axis). 
	 * @param	?quad	The quad to draw on screen. 
	 */
	public function draw(drawable:love2d.utils.Drawable, ?x:Float = 0, ?y:Float = 0, ?r:Float = 0, ?sx:Float = 1, ?sy:Float = 1, ?ox:Float = 0, ?oy:Float = 0, ?kx:Float = 0, ?ky:Float = 0, ?quad:Quad = null) {
		drawable.draw(x, y, r, sx, sy, ox, oy, kx, ky, quad);
	}
	
	@:allow(love2d) private function bitmap(bd:BitmapData, x:Float = 0, y:Float = 0, ?scaleX:Float = 1, ?scaleY:Float = 1, ?angle:Float = 0, ?originX:Float = 0, ?originY:Float = 0, ?kx:Float = 0, ?ky:Float = 0, ?quad:Quad = null) {
		//gr.clear();
		_mat.identity();
		//_mat.translate( -originX, -originY);
		if (quad != null) {
			_mat.translate(-quad._x, -quad._y);
		} else if (angle != 0) _mat.rotate(angle);
		_mat.scale(scaleX, scaleY);
		_mat.translate(x, y);
		/*_colorTransform.redMultiplier = Love.handler.color.r / 255;
		_colorTransform.greenMultiplier = Love.handler.color.g / 255;
		_colorTransform.blueMultiplier = Love.handler.color.b / 255;
		_colorTransform.alphaMultiplier = Love.handler.color.a / 255;*/
		
		Lib.trace("1");
		
		var rt:BitmapData;
		/*if (_canvas == null) */rt = Love.handler.canvas;
		//else rt = _canvas._bitmapData;
		Love.handler.canvas.draw(bd, _mat, _colorTransform, _blendMode);
		Lib.trace("2");
		/*if (quad != null) {
			_bufferRect.x = x + ( - originX) * scaleX;
			_bufferRect.y = y + ( - originY) * scaleY;
			_bufferRect.width = quad._width * scaleX;
			_bufferRect.height = quad._height * scaleY;
			rt.draw(bd, _mat, _colorTransform, _blendMode, _bufferRect, false);
		}
		else {
			_bufferRect.setEmpty();
			rt.draw(bd, _mat, _colorTransform, _blendMode);
		}*/
	}
	
	/**
	 * Draws text on screen.
	 * @param	text	The text to draw. 
	 * @param	x	The position to draw the object (x-axis). 
	 * @param	y	The position to draw the object (y-axis). 
	 * @param	?r	Orientation (radians). 
	 * @param	?sx	Scale factor (x-axis). 
	 * @param	?sy	Scale factor (y-axis). 
	 * @param	?ox	Origin offset (x-axis). 
	 * @param	?oy	Origin offset (y-axis). 
	 * @param	?kx Shearing factor (x-axis). 
	 * @param	?ky	Shearing factor (y-axis). 
	 */
	public function print(text:String, x:Float = 0, y:Float = 0, ?r:Float = 0, ?sx:Float = 1, ?sy:Float = 1, ?ox:Float = 0, ?oy:Float = 0, ?kx:Float = 0, ?ky:Float = 0) {
		_textField.textColor = Love.handler.intColor;
		_textField.visible = true;
		_textField.text = text;
		_textField.x = -ox;
		_textField.y = -oy;
		_mat.identity();
		//_mat.translate(-ox, -oy);
		_mat.scale(sx, sy);
		if (r != 0) _mat.rotate(r);
		_mat.translate(x, y);
		
		var rt:BitmapData;
		if (_canvas == null) rt = Love.handler.canvas;
		else rt = _canvas._bitmapData;
		
		rt.draw(_textField, _mat);
	}
	
	/**
	 * Draws formatted text, with word wrap and alignment. 
	 * @param	text	A text string. 
	 * @param	x	The position on the x-axis. 
	 * @param	y	The position on the y-axis. 
	 * @param	limit	Wrap the line after this many horizontal pixels. 
	 * @param	?align	The alignment. 
	 * @param	?r	Orientation (radians). 
	 * @param	?sx	Scale factor (x-axis). 
	 * @param	?sy	Scale factor (y-axis). 
	 * @param	?ox	Origin offset (x-axis). 
	 * @param	?oy	Origin offset (y-axis). 
	 * @param	?kx	Shearing factor (x-axis). 
	 * @param	?ky	Shearing factor (y-axis). 
	 */
	public function printf(text:String, x:Float = 0, y:Float = 0, limit:Int, ?align:String = "left", ?r:Float = 0, ?sx:Float = 1, ?sy:Float = 1, ?ox:Float = 0, ?oy:Float = 0, ?kx:Float = 0, ?ky:Float = 0) {
		_textFormat.align = switch(align) {
			case "left": TextFormatAlign.LEFT;
			case "right": TextFormatAlign.RIGHT;
			case "center": TextFormatAlign.CENTER;
			case "justify": TextFormatAlign.JUSTIFY;
			default: TextFormatAlign.LEFT;
		}
		
		print(text, x, y, r, sx, sy, ox, oy, kx, ky);
	}
	
	// constructors
	
	/**
	 * Creates a new Image from a filepath, File or an ImageData. 
	 * @param	data Data.
	 * @return An Image object which can be drawn on screen. 
	 */
	public function newImage(data:Dynamic):Image {
		return new Image(data);
	}
	
	/**
	 * Creates a new Font. 
	 * @param	data Data.
	 * @param	?size = 12 The size of the font in pixels. 
	 * @return A Font object which can be used to draw text on screen. 
	 */
	public function newFont(data:Dynamic, ?size = 12):Font {
		return new Font(data, size);
	}
	
	/**
	 * Creates a new SpriteBatch object.
	 * @param	image The Image to use for the sprites.
	 * @param	?size The max number of sprites.
	 * @param	?usageHint The expected usage of the SpriteBatch.
	 * @return The new SpriteBatch. 
	 */
	public function newSpriteBatch(image:Image, ?size:Int = 1000, ?usageHint:String = "dynamic"):SpriteBatch {
		return new SpriteBatch(image, size, usageHint);
	}
	
	/**
	 * Creates a new Quad. 
	 * @param	x The top-left position along the x-axis. 
	 * @param	y The top-left position along the y-axis. 
	 * @param	width The width of the Quad. (Must be greater than 0.) 
	 * @param	height The height of the Quad. (Must be greater than 0.) 
	 * @param	sx The reference width, the width of the Image. (Must be greater than 0.) 
	 * @param	sy The reference height, the height of the Image. (Must be greater than 0.) 
	 * @return The new Quad. 
	 */
	public function newQuad(x:Float = 0, y:Float = 0, width:Int = 1, height:Int = 1, sx:Int, sy:Int):Quad {
		return new Quad(x, y, width, height, sx, sy);
	}
	
	/**
	 * Creates a new Canvas object for offscreen rendering. 
	 * @param	?width	The desired width of the Canvas. 
	 * @param	?height	The desired height of the Canvas. 
	 * @param	?format	The desired texture format of the Canvas. 
	 * @return	A new Canvas with specified width and height. 
	 */
	public function newCanvas(?width:Int = null, ?height:Int = null, ?format:String = "normal"):Canvas {
		return new Canvas(width, height, format);
	}
	
	/*public function newParticleSystem(image:Image, ?buffer:Int = 1000):ParticleSystem {
		return new ParticleSystem(image, buffer);
	}*/
}