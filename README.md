# lab
Machine Learning Experiments

![image](https://user-images.githubusercontent.com/3028982/109432721-97b53a00-79da-11eb-83e9-cba9b9486eef.png)

# references

https://github.com/doctorcorral/gyx (huge thanks, very quick to understand)  
https://github.com/openai/baselines  
https://github.com/openai/gym  

# readings

https://www.freecodecamp.org/news/a-brief-introduction-to-reinforcement-learning-7799af5840db/  
https://www.freecodecamp.org/news/an-introduction-to-q-learning-reinforcement-learning-14ac0b4493cc/  
  
https://www.youtube.com/watch?v=oOmcGQXJRXM  
https://github.com/pythonlessons/Reinforcement_Learning  

# deps (todo podman)

libblas-dev  
pip3 install gym  
pip3 install gym[atari]  

# goals

- [X] frozenlake
- [ ] blackjack
- [ ] ?
- [ ] slay_the_spire
- [ ] 3dnavmesh https://montreal.ubisoft.com/en/deep-reinforcement-learning-for-navigation-in-aaa-video-games/

# slay_the_spire
At 1x speed, we can improve
![stsdemo-2021-03-05_01 26 11](https://user-images.githubusercontent.com/3028982/110076204-1e0eaa80-7d52-11eb-9837-794147695b3d.gif)

```
Modding notes!
We need to make some modifications to slay_the_spire, to expose a GYM API ontop of it. (work in constant progress)

Some cards are currently removed due to complexity to implement them atm, check CardLibrary.java.
Dont modifiy `AbstractDungeon.java` if decompiled by CFR, it subtly breaks the RNG generator.
Alot more work is needed to make the actions faster and never crash.
SlayTheSpire.test_hardcoded_onlymobs_nocards() gives a good indication on the level of optimization, currently the run takes me about 5100ms.


Getting started!

Install the game, version dated `2020-12-13`, and copy `desktop-1.0.jar` into `./priv/slay_the_spire/6661e72999ce8b0e2b6f62809e8b2737.jar`.
The md5sum of `6661e72999ce8b0e2b6f62809e8b2737.jar` should be `6661e72999ce8b0e2b6f62809e8b2737`.
Make it readonly `chmod 0444 6661e72999ce8b0e2b6f62809e8b2737.jar`

Download cfr java decompiler. `wget https://www.benf.org/other/cfr/cfr-0.151.jar` and move it to `./priv/slay_the_spire/`.

Cd into and look at `./priv/slay_the_spire/build.sh` and eventually run it to get the work environment setup.

./priv/slay_the_spire/config/ directory contains the base save file + all unlocks

Apply patch_final.diff into your 6661e72999ce8b0e2b6f62809e8b2737/ dir

run build.sh again


Updating!

Making a new patch
git diff --no-index 6661e72999ce8b0e2b6f62809e8b2737-original/ 6661e72999ce8b0e2b6f62809e8b2737/ > patch_noanim.diff

Running vanilla game
java -jar ../6661e72999ce8b0e2b6f62809e8b2737.jar

```
