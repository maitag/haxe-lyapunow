package;

import peote.view.*;

class Lyapunow implements Element
{
	// position in pixel (relative to upper left corner of Display)
	@posX @const public var x:Int = 0;
	@posY @const public var y:Int = 0;
	
	// size in pixel
	@sizeX @varying @const @formula("uResolution.x") var w:Int;
	@sizeY @varying @const @formula("uResolution.y") var h:Int;

	

	
	// --------------------------------------------------------------------------	
	
	static public var buffer:Buffer<Lyapunow>;
	static public var program:Program;	
	
	static public function init(display:Display)
	{	
		buffer = new Buffer<Lyapunow>(1);
		program = new Program(buffer);
		
		program.injectIntoFragmentShader(
		"
			float func(float x, float y, float a, float b)
			{
				return a*sin(x+y)*sin(x+y)+b;
				// return #FORMULA;
			}

			float deriv(float x, float y, float a, float b)
			{
				return a*sin(2.0*(x+y));
				// return #DERIVATE;
			}

			void pre_step(inout float x, vec2 p, float p1, float p2)
			{
				x = func(x,p.x,p1,p2);
				x = func(x,p.y,p1,p2);
			}

			void main_step(inout float index, inout int iter, inout float x, vec2 p, float p1, float p2, float balance)
			{
				x = func(x,p.x,p1,p2);
				index += (  log(abs(deriv(x,p.x,p1,p2)))*balance + deriv(x,p.x,p1,p2)*(1.0-balance)  ) / 2.0;
				x = func(x,p.y,p1,p2);
				index += (  log(abs(deriv(x,p.y,p1,p2)))*balance + deriv(x,p.y,p1,p2)*(1.0-balance)  ) / 2.0;
				iter = iter + 2;
			}

			vec4 lyapunow()
			{
				float uStart = 0.0;
				vec2 uPosition = vec2(0.0, 0.0);
				vec2 uScale = vec2(800.0/vSize.x, 800.0/vSize.y);
				vec2 uParam = vec2(2.5, 2.0);
				vec2 uIteration = vec2(0.0, 5.0);
				float uBalance = 0.5;
				vec3 uColpos = vec3(1.0, 0.0, 0.0);
				vec3 uColmid = vec3(0.0, 0.0, 0.0);
				vec3 uColneg = vec3(0.0, 0.0, 1.0);


				// Parameter
				float x = uStart;
				vec2 p = (vTexCoord - uPosition) / uScale;
				float p1 = uParam.x;
				float p2 = uParam.y;
				int iter_pre =  int(floor(uIteration.x));
				int iter_main = int(floor(uIteration.y));
				float nabla_pre = uIteration.x - float(iter_pre);
				float nabla_main = uIteration.y - float(iter_main);
				
				float index = 0.0;
				int iter = 0;
				
				// pre-iteration ##########################
				
				for (int i = 0; i < 21; i++) {
					if (i < iter_pre)
					{
						pre_step(x, p, p1, p2);
					}
				}
				if (nabla_pre != 0.0) {
					float x_pre = x;
					pre_step(x, p, p1, p2);
					x = x*nabla_pre + x_pre*(1.0-nabla_pre);
				}
					
				// main-iteration ########################
				
				for (int i = 0; i < 201; i++) {
					if (i < iter_main)
					{
						main_step(index, iter, x, p, p1, p2, uBalance);
					}
				}
				
				if (nabla_main == 0.0) {
					index = (iter != 0) ? index/float(iter) : 0.0;
				}
				else {
					float index_pre = (iter != 0) ? index/float(iter) : 0.0;

					main_step(index, iter, x, p, p1, p2, uBalance);

					index = (iter != 0) ? index/float(iter) : 0.0;
					index = index*nabla_main + index_pre*(1.0-nabla_main);
				}

				return vec4( index*( (index > 0.0) ? uColpos-uColmid : uColmid-uColneg   )+uColmid, 1.0 );
			}			
		"
		, false // inject uTime
		);
		
		program.setColorFormula( 'lyapunow()' );
		display.addProgram(program);


        buffer.addElement( new Lyapunow() );
	}
	
}