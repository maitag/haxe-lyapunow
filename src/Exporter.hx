package;

import peote.view.UniformFloat;
import peote.view.Color;
import Formula;

import Param.DefaultParams;
import Param.FormulaParams;


class Exporter
{
	static public function generateOSL(formula:Formula, sequence:Array<String>,
		positionX:UniformFloat, positionY:UniformFloat, scaleX:UniformFloat, scaleY:UniformFloat, 
		defaultParams:DefaultParams, formulaParams:FormulaParams)
	{

		var func:String = formula.toString("glsl");
		var deriv:String = formula.derivate("i").simplify().toString("glsl");
			
		trace("func", func);
		trace("derivate", deriv);

		var input_param:String = "";
		var extra_param:String = "";
		var extra_func_param:String = "";

		for (p in formula.params()) {
			if ( p=="i" || p=="n" ) continue;
			var v = formulaParams.get(p);
			if ( !( p == "x" || p == "y" || p == "z") ) input_param += 'float Param_$p = ${v.value},\n\t';

			if (p=="x") extra_param += ",p[0]";
			else if (p=="y") extra_param += ",-p[1]";
			else if (p=="z") extra_param += ",p[2]";
			else extra_param += ',Param_$p';

			if ( p=="x" || p=="y" ) extra_func_param += ',float $p';
			else extra_func_param += ',float ${v.identifier}';
			
		}
		
		var pre_sequence:String = "";
		var main_sequence:String = "";

		for (s in sequence) {
			if (s=="x") s = "p[0]";
			else if (s=="y") s = "-p[1]";
			else if (s=="z") s = "p[2]";
			else s = "Param_"+s;
			s += extra_param;
			pre_sequence += 'i =  func(i, $s);\n\t';
			main_sequence +='i =  func(i, $s);\n\tIndex += (log(abs(deriv(i, $s)))*Balance + (deriv(i, $s))*(1.0-Balance)) / 2.0;\n';
		}


		var osl =

'float func(float i, float n $extra_func_param) {
	return $func;
}
float deriv(float i, float n $extra_func_param) {
	return $deriv;
}

shader node_lyapunov(
	float Start_Index = 0.0,
	float Pre_Iteration = 0.0,
	float Main_Iteration = 1.0,

	$input_param
	
	float Balance = 1.0,
	
	color PosColor = color (1.0, 0.0, 0.0),
	color MidColor = color (0.0, 0.0, 0.0),
	color NegColor = color (0.0, 0.0, 1.0),
	
	point Pos = P,			
	float Scale = 1.0,
	
	output color Color = color (0.0, 0.0, 0.0),		
	output float Index = 0.0,
	output float PosIndex = 0.0,
	output float NegIndex = 0.0			
	)
{
	/* Calculate Lyapunov Index */

	point p = Pos * Scale;
	float i = Start_Index;
	
	int iter_pre =  (int)floor(Pre_Iteration);
	int iter_main = (int)floor(Main_Iteration);
	float iter_main_full = floor(Main_Iteration) * ${sequence.length}.0;
	
	float nabla_pre = Pre_Iteration - (float)iter_pre;
	float nabla_main = Main_Iteration - (float)iter_main;

	/* Pre-iteration */
	
	for(int j = 0; j < iter_pre; j++) {
		$pre_sequence
	}

	if (nabla_pre != 0.0) {
		float i_pre = i;

		$pre_sequence

		i = i*nabla_pre + i_pre*(1.0-nabla_pre);
	}

	/* Main-iteration */
	
	for(int j = 0; j < iter_main; j++) {
		$main_sequence			
	}
	

	if (nabla_main == 0.0) {
		Index = (iter_main_full != 0) ? Index/iter_main_full : 0.0;
	}
	else {
		float index_pre = (iter_main_full != 0) ? Index/iter_main_full : 0.0;
		$main_sequence

		iter_main_full = iter_main_full + ${sequence.length}.0;

		Index = (iter_main_full != 0) ? Index/iter_main_full : 0.0;
		Index = Index*nabla_main + index_pre*(1.0-nabla_main);
	}

	/* separate output */
	if (Index > 0.0) {
		PosIndex = Index;
		Color = Index * (PosColor - MidColor) + MidColor;
	}
	else {
		NegIndex = -Index;
		Color = Index * (MidColor - NegColor) + MidColor;
	}		
}
';
		
		saveOSL(pathOSL, filenameOSL, osl);	
	}

	public static var pathOSL:String = "D:\\maitag\\2024\\blenderfractals\\lyapunov-osl\\";
	public static var filenameOSL:String = "lyapunow.osl";

	public static function saveOSL(path:String, filename:String, text:String) {
		#if html5

		var blob = new js.html.Blob([text], { type: 'text/plain' });
		var url = js.html.URL.createObjectURL(blob);
		var anchor = js.Browser.document.createAnchorElement();
		anchor.href = url;
		anchor.download = filename;
		anchor.click();

		#elseif sys

		var fd = new lime.ui.FileDialog();
		
        fd.onSave.add ( (path) -> {
			trace ("onSave: " + path);
			var r = ~/([^\/\\]+)$/;
			if ( r.match(path) ) {
				filenameOSL = r.matched(1);
				pathOSL = r.replace(path, "");
				trace(pathOSL + filenameOSL);
			}
		});
        fd.onCancel.add ( () -> {
			trace ("cancel");
		});

		fd.save(text, "osl", path + filename, "Save OSL file");

		#end
	}

	// TODO: to override an existing written file without fileselector:
	// sys.io.File.saveContent(path+filename, text);

	







	// TODO:
	/*
		trace("save image");
		
		// data what holds the rgba-imagedata
		var data = textureCanvas.readPixelsUInt8(0, 0, 800, 600);

		// convert into lime Image
		var imageBuffer = new ImageBuffer(lime.utils.UInt8Array.fromBytes(data.view.buffer), 800, 600, 32, PixelFormat.RGBA32);
		imageBuffer.format = RGBA32;
		var image = new Image(imageBuffer);

		// encode image format
		var format = ImageFileFormat.PNG;
		//var format = ImageFileFormat.JPEG;
		//var format = ImageFileFormat.BMP;
		
		var imageData = image.encode(format);
		
		// save into file
		var fileName = "picture." + switch (format) {
			case JPEG:"jpg";
			case BMP:"bmp";
			default: "png";
		};
		
		#if html5
			var arrayBuffer:js.lib.ArrayBuffer = imageData.getData();					
			var blob = new js.html.Blob([arrayBuffer]);
			var url = js.html.URL.createObjectURL(blob);
			var anchor = js.Browser.document.createAnchorElement();
			anchor.href = url;
			anchor.download = fileName;
			anchor.click();				
		#else
			var fileOutput =  sys.io.File.write(fileName, true);
			fileOutput.writeBytes(imageData, 0, imageData.length);
			fileOutput.close();
		#end
	*/
	
}