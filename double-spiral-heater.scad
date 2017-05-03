part="demo"; // [all,demo,mill,throughhole]

// Electrical charachteristics

// Copper at 20 °C, Ohm*mm^2/m
material_specific_resistance=0.018;
// Temperature coefficient of resistance, Ohm/°C
material_tcr=0.004;
// DC Voltage, in Volts
heater_voltage=12;

// Heater conductor sizes

conductor_thickness=0.035;
trace_width=1.2;
// Distance between adjacent traces
trace_distance=0.5;
spiral_max_radius=65;
// Spiral segment angle
step_angle=9;

// Heater solder pads

contact_trace_width=8;
contact_distance=2;
// Distance from the center
contact_hole_distance=85;
contact_hole_width=1.5;
contact_hole_length=3;

// Outer bed shape and fixation

// Distance to fixation holes from center
fixation_radius=87.6;
fixation_angle=18.64;
fixation_hole_diameter=3.2;
base_radius=142;
base_cut_radius=177;
thermistor_hole_diameter=2;
thermistor_to_trace_distance=0.5;
heater_to_polygon_distance=2;

/* [Hidden] */

$fn=32;

conductor_sectional_area=conductor_thickness*trace_width;
conductor_specific_resistance=material_specific_resistance/conductor_sectional_area;

// Radius step per one degree
rstep=((trace_width+trace_distance)*2)/360;
spiral_min_radius=thermistor_hole_diameter+trace_width+2*thermistor_to_trace_distance;
central_contact_hole_diameter=spiral_min_radius-trace_width;
turns_im=(spiral_max_radius-trace_width-trace_distance-spiral_min_radius)/(trace_width+trace_distance)/2;
turns=ceil(turns_im*(360/step_angle))/(360/step_angle);
heater_area=PI*pow(spiral_max_radius,2);
actual_conductor_length1=spiral_length(spiral_min_radius,trace_width,trace_distance,turns,rstep,step_angle)/1000;
actual_conductor_length2=spiral_length(spiral_min_radius+trace_distance+trace_width,trace_width,trace_distance,turns,rstep,step_angle)/1000;
actual_conductor_length=actual_conductor_length1+actual_conductor_length2;
actual_heater_resistance_20=conductor_specific_resistance*actual_conductor_length;
actual_heater_current_20=heater_voltage/actual_heater_resistance_20;
actual_heater_power_20=pow(heater_voltage,2)/actual_heater_resistance_20;
heater_specific_power_20=actual_heater_power_20/heater_area;
actual_heater_resistance_100=actual_heater_resistance_20*(1+material_tcr*(100-20));
actual_heater_current_100=heater_voltage/actual_heater_resistance_100;
actual_heater_power_100=pow(heater_voltage,2)/actual_heater_resistance_100;
heater_specific_power_100=actual_heater_power_100/heater_area;

echo(str("Heater area: ",heater_area/100," cm^2"));
echo(str("Conductor sectional area: ",conductor_sectional_area," mm^2"));
echo(str("Conductor specific resistance: ",conductor_specific_resistance," Ohm/m"));
echo(str("Number of spiral turns: ",turns));
echo(str("Conductor length: ",actual_conductor_length1,"+",actual_conductor_length2,"=",actual_conductor_length," m"));
echo("");
echo(str("Heater resistance at 20 °C: ", actual_heater_resistance_20," Ohm"));
echo(str("Heater current at 20 °C: ",actual_heater_current_20," A"));
echo(str("Heater power at 20 °C: ",actual_heater_power_20," W"));
echo(str("Heater specific power at 20 °C: ",heater_specific_power_20*100," W/cm^2"));
echo("");
echo(str("Heater resistance at 100 °C: ", actual_heater_resistance_100," Ohm"));
echo(str("Heater current at 100 °C: ",actual_heater_current_100," A"));
echo(str("Heater power at 100 °C: ",actual_heater_power_100," W"));
echo(str("Heater specific power at 100 °C: ",heater_specific_power_100*100," W/cm^2"));

if (part=="all") {
    difference() {
        bed_shape();

        bed_holes();
        offset(heater_to_polygon_distance)
            heater_shape();
    }
    
    difference() {
        intersection() {
            heater_shape();
            bed_shape();
        }
        contact_holes();
    }
} else if (part=="demo") {
    fr4=1.5;
    
    difference() {
        union() {
            color("khaki")
                linear_extrude(height=fr4)
                    bed_shape();
        
            color("sandybrown") {
                translate([0,0,fr4]) {
                    linear_extrude(height=conductor_thickness) {
                        difference() {
                            bed_shape();
                    
                            offset(heater_to_polygon_distance)
                                heater_shape();
                        }
                        difference() {
                            intersection() {
                                heater_shape();
                                bed_shape();
                            }
                        }
                    }
                }
            }
        }
        
        #translate([0,0,-10])
        {
            linear_extrude(height=fr4+20) {
                bed_holes();
                contact_holes();
            }
        }
    }
} else if (part=="mill") {
    difference() {
        bed_shape();

        offset(heater_to_polygon_distance)
            heater_shape();
    }
    intersection() {
        heater_shape();
        bed_shape();
    }
} else if (part=="throughhole") {
    difference() {
        bed_shape();
        
        bed_holes();
        contact_holes();
    }
}

function sumv(v,i=0,acc=0) = i==len(v)-1 ? acc+v[i] : sumv(v,i+1,acc+v[i]);

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
        [for(t=[-180:step_angle:360*turns+0.001]) 
            [(r-width/2+t*rstep+width+gap)*sin(t),(r-width/2+t*rstep+width+gap)*cos(t)]],
        [for(t=[360*turns:-step_angle:-180-0.001]) 
            [(r+width/2+t*rstep+width+gap)*sin(t),(r+width/2+t*rstep+width+gap)*cos(t)]]
            ));
}

module double_spiral_central_contact()
{
    for (mm=[0,1]) {
        rotate(mm*180) {
            translate([0,(trace_width/2+central_contact_hole_diameter/2)]) {
                difference() {
                    circle(d=2*trace_width+central_contact_hole_diameter);
                    circle(d=central_contact_hole_diameter);
                    translate([0,-2*central_contact_hole_diameter])
                        square(4*central_contact_hole_diameter);
                }
            }
        }
    }
}

module contact_holes()
{
    translate([0,contact_hole_distance]) {
        translate([-contact_distance/2-contact_trace_width/2,0]) {
            hull() {
                translate([0,(contact_hole_length-contact_hole_width)/2])
                    circle(d=contact_hole_width);
                translate([0,-(contact_hole_length-contact_hole_width)/2])
                    circle(d=contact_hole_width);
            }
        }

        translate([contact_distance/2+contact_trace_width/2,0]) {
            hull() {
                translate([0,(contact_hole_length-contact_hole_width)/2])
                    circle(d=contact_hole_width);
                translate([0,-(contact_hole_length-contact_hole_width)/2])
                    circle(d=contact_hole_width);
            }
        }
    }
}

module double_spiral_ends()
{
    translate([-contact_distance/2-contact_trace_width,spiral_min_radius+turns*rstep*360+trace_distance+trace_width/2])
        square([contact_trace_width,contact_hole_distance-spiral_max_radius+contact_hole_length/2+contact_trace_width/2]);

    translate([contact_distance/2,spiral_min_radius+turns*rstep*360-trace_width/2]) {
        union() {
            square([contact_trace_width,contact_hole_distance-spiral_max_radius+contact_hole_length/2+contact_trace_width/2+trace_distance+trace_width]);
            translate([-contact_distance/2-.001,0])
                square([contact_distance/2+1,trace_width]);
        }
    }
}

module heater_shape()
{
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
}

module bed_shape()
{
    intersection() {
        rotate(-30)
            circle(r=base_radius,$fn=3);
        rotate(30)
           circle(r=base_cut_radius,$fn=3);
    }
}

module bed_holes()
{
    for (a=[0:120:360]) {
        rotate(-30+a-fixation_angle)
            translate([fixation_radius,0])
                circle(d=fixation_hole_diameter);
        rotate(-30+a+fixation_angle)
            translate([fixation_radius,0])
                circle(d=fixation_hole_diameter);
    }
    rotate(-360*(ceil(turns)-turns))
        translate([0,(trace_width/2+central_contact_hole_diameter/2)])
            circle(d=thermistor_hole_diameter);
}
