Wave32[] load_waves() {
    Wave32[] wave_list = new Wave32[32];    //There seem to be 32 different waveforms in GXSCC.
    
    
    int[] wd_00 = {7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7};
    wave_list[0] = new Wave32(wd_00);
    int[] wd_01 = {7, 7, 7, 7, 7, 7, 7, 7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7};
    wave_list[1] = new Wave32(wd_01);
    int[] wd_02 = {7, 7, 7, 7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7};
    wave_list[2] = new Wave32(wd_02);
    int[] wd_03 = {0, 0, -1, -2, -3, -4, -5, -6, -7, -6, -5, -4, -3, -2, -1, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1, 0};
    wave_list[3] = new Wave32(wd_03);
    int[] wd_04 = {0, 1, 3, 5, 7, 5, 3, 1, 0, -1, -3, -5, -7, -5, -3, -1, 0, 1, 3, 5, 7, 5, 3, 1, 0, -1, -3, -5, -7, -5, -3, -1};
    wave_list[4] = new Wave32(wd_04);
    int[] wd_05 = {0, 1, 2, 4, 5, 6, 6, 7, 7, 7, 6, 6, 5, 4, 2, 1, 0, -1, -2, -4, -5, -6, -6, -7, -7, -7, -6, -6, -5, -4, -2, -1};
    wave_list[5] = new Wave32(wd_05);
    int[] wd_06 = {0, 0, 0, 0, 0, 6, 6, 0, 0, -7, -7, -7, 0, 0, 0, 0, 6, 6, 6, 0, -7, -7, 0, 0, 0, 0, 6, 6, 0, 0, -7, -7};
    wave_list[6] = new Wave32(wd_06);
    int[] wd_07 = {0, 0, 0, -7, 0, 6, 6, 6, 0, 0, 0, -7, 0, 0, 0, -7, -7, -7, -7, 0, -7, -7, 0, 0, 0, 0, -7, -7, -7, 0, -7, -7};
    wave_list[7] = new Wave32(wd_07);
    int[] wd_08 = {-7, -7, -6, -6, -5, -5, -4, -4, -3, -3, -2, -2, -1, -1, 0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6};
    wave_list[8] = new Wave32(wd_08);
    int[] wd_09 = {5, 5, 5, 5, 5, 5, 5, 5, -7, -7, -7, -7, -7, -7, -7, -7, 5, 5, 5, -7, -7, -7, 5, 5, 5, 5, 5, -7, -7, -7, -7, -7};
    wave_list[9] = new Wave32(wd_09);
    int[] wd_10 = {0, 2, 4, 5, 6, 5, 4, 2, 0, -2, -4, -5, -6, -5, -4, -2, 0, 3, 5, 6, 5, 3, 0, -3, -5, -6, -5, -3, 0, 6, 0, -6};
    wave_list[10] = new Wave32(wd_10);
    int[] wd_11 = {0, 6, 4, 1, 4, 6, 2, 0, 4, 7, 5, 0, 2, 3, 0, -4, 0, 5, 0, -1, 0, 0, -4, -6, -3, 0, -2, -5, -3, 0, -3, -5};
    wave_list[11] = new Wave32(wd_11);
    int[] wd_12 = {2, 4, 4, 2, 0, 0, 0, 3, 5, 6, 5, 2, 0, -1, -1, 0, 1, 1, 0, -3, -5, -6, -5, -3, 0, 0, -2, -4, -4, -2, 0, 0};
    wave_list[12] = new Wave32(wd_12);
    int[] wd_13 = {-5, -6, -6, -6, -5, -5, -4, -4, -3, -3, -2, -2, -1, -1, 0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5, 4};
    wave_list[13] = new Wave32(wd_13);
    int[] wd_14 = {0, 0, 1, 2, 0, 4, 4, 0, 5, 0, 4, 4, 0, 2, 1, 0, 0, -2, 0, -4, 0, -6, 0, -7, 0, -7, 0, -6, 0, -4, 0, -2};
    wave_list[14] = new Wave32(wd_14);
    int[] wd_15 = {6, 6, 5, -7, -6, -6, -7, -7, 3, 3, 2, -7, -6, -6, -7, -7, 1, 1, 0, -7, -6, -6, -7, -7, 0, 0, 0, -7, -6, -6, -7, -7};
    wave_list[15] = new Wave32(wd_15);
    int[] wd_16 = {0, 1, 2, 3, 4, 4, 5, 5, 5, 4, 4, 3, 2, 1, 0, 0, -2, -4, -6, -7, -7, -6, -4, -2, 0, 2, 4, 5, 5, 4, 2, 0};
    wave_list[16] = new Wave32(wd_16);
    int[] wd_17 = {0, 0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1, 0, 0, -1, -3, -5, -7, -5, -3, -1, 0, 1, 3, 5, 7, 5, 3, 1};
    wave_list[17] = new Wave32(wd_17);
    int[] wd_18 = {0, 1, 2, 4, 5, 6, 6, 7, 7, 7, 6, 6, 5, 4, 2, 1, 0, -1, -3, -5, -7, -5, -3, -1, 0, 1, 3, 5, 7, 5, 3, 1};
    wave_list[18] = new Wave32(wd_18);
    int[] wd_19 = {0, 0, -1, -2, -3, -4, -5, -6, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, 7, 6, 5, 4, 3, 2, 1, 0};
    wave_list[19] = new Wave32(wd_19);
    int[] wd_20 = {-7, -4, -3, 0, 1, 2, 2, 1, 0, -1, -2, -1, 2, 4, 6, 6, 6, 2, -1, -7, -7, -6, -6, -6, 0, 7, 6, 6, 5, 0, -3, -6};
    wave_list[20] = new Wave32(wd_20);
    int[] wd_21 = {0, 1, 2, 4, 5, 6, 6, 7, 7, 7, 6, 6, 5, 4, 2, 1, -7, -6, -5, -4, -3, -2, -1, 0, 0, 0, 1, 2, 3, 4, 5, 6};
    wave_list[21] = new Wave32(wd_21);
    int[] wd_22 = {0, 4, 5, 6, 6, 7, 7, 7, 7, 7, 7, 7, 6, 6, 5, 4, 0, -4, -5, -6, -6, -7, -7, -7, -7, -7, -7, -7, -6, -6, -5, -4};
    wave_list[22] = new Wave32(wd_22);
    int[] wd_23 = {-7, -3, 1, 7, 2, -3, -7, -6, -5, -3, -1, 0, 1, 3, 4, 5, 6, 7, 7, 7, 7, 7, 6, 5, 4, 3, 1, 0, -1, -3, -5, -6};
    wave_list[23] = new Wave32(wd_23);
    int[] wd_24 = {0, 3, 7, 3, 0, 0, -1, -2, -3, -4, -4, -5, -5, -6, -6, -6, -7, -7, -7, -7, -7, -6, -6, -6, -5, -5, -4, -4, -3, -2, -1, 0};
    wave_list[24] = new Wave32(wd_24);
    int[] wd_25 = {0, 3, 7, 3, 0, -3, 0, -3, 0, -1, -2, -3, -4, -4, -5, -5, -6, -6, -7, -7, -7, -7, -7, -6, -6, -5, -5, -4, -4, -3, -2, -1};
    wave_list[25] = new Wave32(wd_25);
    int[] wd_26 = {-7, -3, -3, -3, 0, -1, 2, 1, 6, 3, 3, 3, 0, 1, -3, -6, -3, -3, -3, 0, -1, 2, 1, 6, 3, 3, 3, 0, 1, -1, -5, -6};
    wave_list[26] = new Wave32(wd_26);
    int[] wd_27 = {0, 3, 7, 3, 0, -3, -7, -3, 0, 3, 7, 3, 0, -3, 0, 3, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3, 3};
    wave_list[27] = new Wave32(wd_27);
    int[] wd_28 = {0, 2, 0, 2, 3, 4, 5, 5, 6, 7, 6, 7, 3, 0, 0, 0, 6, -7, 5, 4, 0, 0, 0, 2, 6, -7, -7, 5, 5, -1, -6, -7};
    wave_list[28] = new Wave32(wd_28);
    int[] wd_29 = {-7, 0, 0, 0, 6, 6, 0, 0, -7, -7, -7, 0, 0, 0, 0, 6, 6, 6, 6, -7, 7, -7, -7, -3, 0, 1, 3, 3, 3, 1, 0, -3, -7};
    wave_list[29] = new Wave32(wd_29);
    int[] wd_30 = {0, 3, 7, 3, 0, -3, -7, -3, 0, 3, 7, 3, 0, -3, 0, 3, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 7, 7, 7, 7, 7, 7};
    wave_list[30] = new Wave32(wd_30);
    int[] wd_31 = {6, 7, 6, 5, 4, 3, 1, -2, -6, -7, -6, -5, -3, -1, 0, 0, 1, 0, 0, -2, -3, -4, -6, -7, -6, -2, 1, 3, 4, 5, 6, 7};
    wave_list[31] = new Wave32(wd_31);
    
    
    return wave_list;
}