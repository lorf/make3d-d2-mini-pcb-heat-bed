// Copper at 20 °C, Ohm*mm^2/m
material_specific_resistance=0.018;
// Temperature coefficient of resistance, Ohm/°C
material_tcr=0.004;
conductor_thickness=0.035;
// DC Voltage, in Volts
heater_voltage=12;

trace_width=1.8;
// Distance between adjacent traces
trace_distance=1;
spiral_min_radius=3;
spiral_max_radius=120;

contact_trace_width=8;
contact_distance=2;
// Distance from the spiral
contact_hole_distance=20;
contact_hole_width=1.5;
contact_hole_length=3;

// Spiral segment angle
step_angle=9;

/* [Hidden] */

$fn=32;

conductor_section_area=conductor_thickness*trace_width;
conductor_specific_resistance=material_specific_resistance/conductor_section_area;

// Radius step per one degree
rstep=((trace_width+trace_distance)*2)/360;
turns_im=(spiral_max_radius-trace_width-trace_distance-spiral_min_radius)/(trace_width+trace_distance)/2;
turns=ceil(turns_im*(360/step_angle))/(360/step_angle);
actual_conductor_length1=spiral_length(spiral_min_radius,trace_width,trace_distance,turns,rstep,step_angle)/1000;
actual_conductor_length2=spiral_length(spiral_min_radius+trace_distance+trace_width,trace_width,trace_distance,turns,rstep,step_angle)/1000;
actual_conductor_length=actual_conductor_length1+actual_conductor_length2;
actual_conductor_resistance_20=conductor_specific_resistance*actual_conductor_length;
actual_conductor_current_20=heater_voltage/actual_conductor_resistance_20;
actual_conductor_wattage_20=pow(heater_voltage,2)/actual_conductor_resistance_20;
actual_conductor_resistance_100=actual_conductor_resistance_20*(1+material_tcr*(100-20));
actual_conductor_current_100=heater_voltage/actual_conductor_resistance_100;
actual_conductor_wattage_100=pow(heater_voltage,2)/actual_conductor_resistance_100;

echo(str("Conductor section area: ",conductor_section_area," mm^2"));
echo(str("Conductor specific resistance: ",conductor_specific_resistance," Ohm/m"));
echo(str("Number of spiral turns: ",turns));
echo(str("Conductor length: ",actual_conductor_length1,"+",actual_conductor_length2,"=",actual_conductor_length," m"));
echo(str("Conductor resistance at 20°C: ", actual_conductor_resistance_20," Ohm"));
echo(str("Conductor current at 20°C: ",actual_conductor_current_20," A"));
echo(str("Conductor wattage at 20°C: ",actual_conductor_wattage_20," W"));
echo(str("Conductor resistance at 100°C: ", actual_conductor_resistance_100," Ohm"));
echo(str("Conductor current at 100°C: ",actual_conductor_current_100," A"));
echo(str("Conductor wattage at 100°C: ",actual_conductor_wattage_100," W"));

// Draw a double spiral
difference() {
    union() {
        rotate(-360*(ceil(turns)-turns)) {
            double_spiral(spiral_min_radius,trace_width,trace_distance,turns,rstep,step_angle);
            double_spiral_central_contact();
        }
        double_spiral_ends();
    }
    
    // Cleanup space between contacts
    translate([-contact_distance/2,spiral_min_radius+turns*rstep*360+trace_width/2+trace_distance/2])
        square([contact_distance,trace_distance+trace_width]);
}

function sumv(v,i=0) = (i==len(v)-1 ? v[i] : v[i] + sumv(v,i+1));

function spiral_length(r=1,width=2,gap=2,turns=3,rstep,step_angle) = 
    sumv([for(t=[0:step_angle:360*turns+0.001])
        2*(r+(t+step_angle/2)*rstep)*sin(step_angle/2)]);

module double_spiral(r=10,width=2,gap=2,turns=3,rstep,step_angle)
{
    polygon(points=concat(
        [for(t=[0:step_angle:360*turns+0.001])
            [(r-width/2+t*rstep)*sin(t),(r-width/2+t*rstep)*cos(t)]],
        [for(t=[360*turns:-step_angle:-0.001])
            [(r+width/2+t*rstep)*sin(t),(r+width/2+t*rstep)*cos(t)]]
            ));
    polygon(points=concat(
        [for(t=[0:step_angle:360*turns+0.001]) 
            [(r-width/2+t*rstep+width+gap)*sin(t),(r-width/2+t*rstep+width+gap)*cos(t)]],
        [for(t=[360*turns:-step_angle:-0.001]) 
            [(r+width/2+t*rstep+width+gap)*sin(t),(r+width/2+t*rstep+width+gap)*cos(t)]]
            ));
}

module double_spiral_central_contact()
{
    translate([0,spiral_min_radius+trace_width/2+trace_distance/2]) {
        difference() {
            circle(d=2*trace_width+trace_distance);
            circle(d=trace_distance);
            translate([0,-trace_width-trace_distance/2-1])
                square([trace_width+trace_distance/2+1,2*trace_width+trace_distance+2]);
        }
    }
}

module double_spiral_ends()
{
    translate([-contact_distance/2-contact_trace_width,spiral_min_radius+turns*rstep*360+trace_distance+trace_width/2]) {
        difference() {
            square([contact_trace_width,contact_hole_distance+contact_hole_length/2+contact_trace_width/2]);
            translate([contact_trace_width/2,contact_hole_distance]) {
                hull() {
                    translate([0,(contact_hole_length-contact_hole_width)/2])
                        circle(d=contact_hole_width);
                    translate([0,-(contact_hole_length-contact_hole_width)/2])
                        circle(d=contact_hole_width);
                }
            }
        }
    }

    translate([contact_distance/2,spiral_min_radius+turns*rstep*360-trace_width/2]) {
        difference() {
            union() {
                square([contact_trace_width,contact_hole_distance+contact_hole_length/2+contact_trace_width/2+trace_distance+trace_width]);
                translate([-contact_distance/2-.001,0])
                    square([contact_distance/2+1,trace_width]);
            }
            translate([contact_trace_width/2,contact_hole_distance+trace_distance+trace_width]) {
                hull() {
                    translate([0,(contact_hole_length-contact_hole_width)/2])
                        circle(d=contact_hole_width);
                    translate([0,-(contact_hole_length-contact_hole_width)/2])
                        circle(d=contact_hole_width);
                }
            }
        }
    }
}
