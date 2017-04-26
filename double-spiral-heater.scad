part="demo"; // [demo,mill,throughhole]

// Copper at 20 °C, Ohm*mm^2/m
material_specific_resistance=0.018;
// Temperature coefficient of resistance, Ohm/°C
material_tcr=0.004;
conductor_thickness=0.035;
// DC Voltage, in Volts
heater_voltage=12;

trace_width=0.8;
// Distance between adjacent traces
trace_distance=1;
spiral_min_radius=3;
spiral_max_radius=65;

contact_trace_width=8;
contact_distance=2;
// Distance from the spiral
contact_hole_distance=12;
contact_hole_width=1.5;
contact_hole_length=3;

// Spiral segment angle
step_angle=9;

// Outer edges and fixation
fixation_radius=87.6;
fixation_angle=37.28/2;
fixation_hole_diameter=3.2;
//base_radius=272.4*sqrt(3)/3-30;
base_radius=spiral_max_radius*2+12;
base_cut_radius=2*101-25;
thermistor_hole=3;

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

if (part=="demo") {
    color("blue") {
        difference() {
            bed_shape();
    
            bed_holes();
            offset(1)
                heater_shape();
        }
    }
    
    difference() {
        heater_shape();
        contact_holes();
    }
} else if (part=="mill") {
    difference() {
        bed_shape();

        offset(1)
            heater_shape();
    }
    heater_shape();
} else if (part=="throughhole") {
    difference() {
        bed_shape();
        
        bed_holes();
        contact_holes();
    }
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

module contact_holes()
{
    translate([0,spiral_min_radius+turns*rstep*360+trace_distance+trace_width/2+contact_hole_distance]) {
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
        square([contact_trace_width,contact_hole_distance+contact_hole_length/2+contact_trace_width/2]);

    translate([contact_distance/2,spiral_min_radius+turns*rstep*360-trace_width/2]) {
        union() {
            square([contact_trace_width,contact_hole_distance+contact_hole_length/2+contact_trace_width/2+trace_distance+trace_width]);
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
                #circle(d=fixation_hole_diameter);
        rotate(-30+a+fixation_angle)
            translate([fixation_radius,0])
                #circle(d=fixation_hole_diameter);
    }
    circle(d=thermistor_hole);
}