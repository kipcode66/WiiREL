/**
 * @file main.h
 * @author your name (you@domain.com)
 * @brief
 * @version 0.1
 * @date YYYY-MM-DD
 *
 * @copyright Copyright (c) YYYY
 *
 */
#pragma once
#include <display/console.h>
#include <tp/f_ap_game.h>

namespace mod
{
    /***********************************************************************************
     * We're creating a cusutom REL file and thus the real main function already ran
     * before we even load this program.
     * That's also why we create a custom namespace to avoid confusing the compiler with the actual main function
     * whilst still having a neat starting function for you to begin your Twilight Princess mod development!
     * Note:
     * If you want to change the namespace "mod" you will have to make adjustments to rel.cpp in libtp_rel!
     *
     * This main function is going to be executed once at the beginning of the game,
     * assuming the REL got loaded in the first place.
     ***********************************************************************************/
    void main();
    void exit();
    class Mod
    {
        public:
            Mod();
            void init();

        private:
            int i;
            libtp::display::Console c;
            void procNewFrame();
            void (*return_fapGm_Execute)() = nullptr;
    };
}  // namespace mod