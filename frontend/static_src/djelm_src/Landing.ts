/*
  Do not manually edit this file, it was auto-generated by djelm
  https://github.com/Confidenceman02/djelm
*/
import defo from "@icelab/defo";

const views = {
    djelmLanding: async (el: HTMLElement, data: any) => {
        //@ts-ignore
        const { Elm } = await import("../src/Landing.elm")

        const app = Elm.Landing.init({
            node: el,
            flags: data,
        });

        return {
            // Called whenever the value of the `djelm` attribute changes
            update: (newData, oldData) => {},
            // Called when the element (or its djelm attribute) is removed from the DOM
            destroy: () => {},
        };
    }
}

defo({ views, prefix: "frontendlanding" })
