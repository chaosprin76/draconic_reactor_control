# persistent instances

Storing a table, holding all runtime-settings, to disk. Some can quit and reenter the programm with our preferences, all for free.
I could also split the process from the interface and have a daemon running all the time. 
It can also be used for keeping some API-internal state persistant. Will be very usefull for keeping variable like :isRaisingSat :isLoweringTemperature.

# Auto-output control optimizing

The first iteration is very configureble, but its hard to get efficient settings. Instead of the config-based tiers1, i should split  the wohle process into 3 phases.

- At the beginning i dont care so much about the saturation. Instead i want to get up the output-rate to ~10 Mrf/t as fast as possible. In this phase, we utilize the temperature-raising in addition to higher-temp-reqs. thorugh raising the conversion level.
I let get the saturation down to 35 and let it raise back to 40 when this is reached.
I addition, the temp should not be higher 5500 degrees.

- When i  have the 10mRf its important to come back to a good fuel-conversion-rate. This can be achieved through letting the saturation raise up 55 - 60 %. 
The lowered temperature is neat byproduct.
Both, saturation and temperature will be more important. I may store the state of both and raise the output only when they are back down to near this stored state.

- From 18mRf on it will be even more important to keep this things up, cause thats the goal and i want to keep the reactor running as long as possible from here.
So i will have to raise saturation at first to 65 - ~70 % and lower the output-raise-steps.
This phase should also enter when a determined conversion-level-threshold is reached, something between 50 and 60 percent.
