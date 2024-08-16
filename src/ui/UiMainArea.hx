package ui;

import peote.ui.config.TextConfig;
import peote.ui.config.AreaConfig;
import peote.ui.interactive.UIArea;
import peote.ui.interactive.UITextLine;
import peote.ui.interactive.interfaces.ParentElement;

import Param.DefaultParams;
import Param.FormulaParams;

class UiMainArea extends UIArea implements ParentElement
{
	var defaultParams:DefaultParams;

	public var formulaInput:UITextLine<UiFontStyle>;
	public var sequenceInput:UITextLine<UiFontStyle>;

	public var formulaParamArea = new Map<String, UiParamArea>();
	public var formulaParamOrder = new Array<String>();
	
	public var iterMainArea:UiParamArea;
	public var iterPreArea:UiParamArea;
	public var startIndexArea:UiParamArea;
	public var balanceArea:UiParamArea;

	var leftSpace:Int = 4;
	var rightSpace:Int = 4;
	var topSpace:Int = 2;
	var gap:Int = 5;
	var paramAreaHeight:Int;
	var paramAreaWidth:Int;
	
	public function new(
		defaultParams:DefaultParams,
		formulaParams:FormulaParams,
		xPosition:Int, yPosition:Int, width:Int, height:Int, zIndex:Int = 0,
		?config:AreaConfig
	) 
	{
		this.defaultParams = defaultParams;
		super(xPosition, yPosition, width, height, zIndex, config);
		
		// -----------------------------------------------------------
		// ---- creating an Area, header and Content-Area ------------
		// -----------------------------------------------------------
		
		paramAreaHeight = Std.int(Ui.fontStyle.height) + 24;
		paramAreaWidth = width - leftSpace - rightSpace;

		
		var textConfig:TextConfig = {
			backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205),
			selectionStyle: Ui.selectionStyle,
			cursorStyle: Ui.cursorStyle,
			textSpace: { left:5, right:5, top:5, bottom:5 },
			undoBufferSize:50
		}
		// --------------------------
		// ---- header textline -----		
		// --------------------------
/*		
		var header = new UITextLine<UiFontStyle>(gap, gap,
			width - gap - gap, headerSize, 
			"Shader Code", fontUi, fontStyleUi, { backgroundStyle:bgStyleHeader, hAlign:HAlign.CENTER }
		);
		// start/stop area-dragging
		header.onPointerDown = (_, e:PointerEvent)-> startDragging(e);
		header.onPointerUp = (_, e:PointerEvent)-> stopDragging(e);
		add(header);
		
*/		
		// --------------------------
		// ------- formula --------
		// --------------------------
		
		formulaInput = new UITextLine<UiFontStyle>(leftSpace, topSpace,
			width - leftSpace - rightSpace,
			Std.int(Ui.fontStyle.height) + textConfig.textSpace.top + textConfig.textSpace.bottom,
			Ui.formula,
			Ui.font, Ui.fontStyle, textConfig
		);
		formulaInput.onPointerDown = function(t, e) {
			t.setInputFocus(e);			
			t.startSelection(e);
		}
		formulaInput.onPointerUp = function(t, e) {
			t.stopSelection(e);
		}
		formulaInput.onInsertText = formulaInput.onDeleteText = function(t, from:Int, to:Int, value:String) {
			// trace("formula on change",from, to, value);
			Ui.formula = t.text;
			Ui.formulaChanged = true;
		}
		add(formulaInput);
		

		// --------------------------
		// ------- sequence ---------
		// --------------------------
		
		sequenceInput = new UITextLine<UiFontStyle>(leftSpace, formulaInput.bottom + gap,
			width - leftSpace - rightSpace,
			Std.int(Ui.fontStyle.height) + textConfig.textSpace.top + textConfig.textSpace.bottom,
			Ui.sequence,
			Ui.font, Ui.fontStyle, textConfig
		);		
		sequenceInput.onPointerDown = function(t, e) {
			t.setInputFocus(e);			
			t.startSelection(e);
		}		
		sequenceInput.onPointerUp = function(t, e) {
			t.stopSelection(e);
		}
		sequenceInput.onInsertText = sequenceInput.onDeleteText = function(t, from:Int, to:Int, value:String) {
			trace("sequenceInput on change",from, to, value);
			Ui.sequence = t.text;
			Ui.sequenceChanged = true;
		}

		// Todo: 
		// sequenceInput.onChange
		
		add(sequenceInput);
		

		// -------------------------------------
		// ------- areas for parameters --------
		// -------------------------------------

		var _y:Int = sequenceInput.bottom + gap;
		
		for (p => param in formulaParams) {
			formulaParamOrder.push(p);
			formulaParamArea.set( p, createParamArea(param, _y) );
			_y += paramAreaHeight + gap;
		}

		// -------------------------------------

		startIndexArea = new UiParamArea( defaultParams.startIndex,
			leftSpace, _y, paramAreaWidth, paramAreaHeight,
			{ backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205) }
		);
		add(startIndexArea);

		// -------------------------------------
		_y += paramAreaHeight + gap;

		iterPreArea = new UiParamArea( defaultParams.iterPre,
			leftSpace, _y, paramAreaWidth, paramAreaHeight,
			{ backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205) }
		);
		add(iterPreArea);

		// -------------------------------------
		_y += paramAreaHeight + gap;

		iterMainArea = new UiParamArea( defaultParams.iterMain,
			leftSpace, _y, paramAreaWidth, paramAreaHeight,
			{ backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205) }
		);
		add(iterMainArea);

		// -------------------------------------
		_y += paramAreaHeight + gap;

		balanceArea = new UiParamArea( defaultParams.balance,
			leftSpace, _y, paramAreaWidth, paramAreaHeight,
			{ backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205) }
		);
		add(balanceArea);


		// --- re-arrange inner content if area size is changing ---
		
		// TODO: outside ?
		onResizeWidth = (_, width:Int, deltaWidth:Int) -> {
			paramAreaWidth = width - leftSpace - rightSpace;

			formulaInput.width = paramAreaWidth;
			sequenceInput.width = paramAreaWidth;

			for (pArea in formulaParamArea) pArea.width = paramAreaWidth;

			startIndexArea.width = paramAreaWidth;
			iterPreArea.width = paramAreaWidth;
			iterMainArea.width = paramAreaWidth;
			balanceArea.width =  paramAreaWidth;
		}
		/*
		onResizeHeight = (_, height:Int, deltaHeight:Int) -> {
			
		}*/

		maxHeight = innerHeight + 6; 
	}	


	// ------------------------------------------------
	// ----- Add/Remove formula-parameter -------------
	// ------------------------------------------------

	function createParamArea(param:Param, y:Int):UiParamArea {
		var paramArea = new UiParamArea( param,
			leftSpace, y, paramAreaWidth, paramAreaHeight,
			{ backgroundStyle:Ui.roundStyle.copy(0x11150fbb, 0xddff2205) }
		);
		add(paramArea);
		return paramArea;
	}

	public function addFormulaParam(p:String, param:Param) {
		// trace("add param widget", p, param);
		var pArea:UiParamArea = createParamArea(param, startIndexArea.y);
		formulaParamArea.set( p, pArea );
		formulaParamOrder.push(p);

		var y_offset = pArea.height + gap;
		startIndexArea.y += y_offset;
		iterPreArea.y += y_offset;
		iterMainArea.y += y_offset;
		balanceArea.y += y_offset;

		updateInnerSize();
		maxHeight = innerHeight + 6;
		height += y_offset;

		updateLayout();

	}

	public function removeFormulaParam(p:String) {
		// trace("remove param widget" , p);
		var pArea:UiParamArea = formulaParamArea.get(p);
		formulaParamArea.remove(p);
		remove(pArea);

		var y_offset = pArea.height + gap;
		for (i in (formulaParamOrder.indexOf(p)+1)...formulaParamOrder.length) {
			pArea = formulaParamArea.get( formulaParamOrder[i] );
			pArea.y -= y_offset;
		}

		formulaParamOrder.remove(p);
		
		startIndexArea.y -= y_offset;
		iterPreArea.y -= y_offset;
		iterMainArea.y -= y_offset;
		balanceArea.y -= y_offset;

		updateInnerSize();
		maxHeight = innerHeight + 6;
		height -= y_offset;
		if (height < minHeight+5) height = minHeight+5;

		updateLayout();
	}

}
