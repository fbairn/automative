import { LightningElement, wire, api } from 'lwc';
import getSearchOptions from "@salesforce/apex/VehicleFinderController.getSearchOptions";
import vehicleSearch from "@salesforce/apex/VehicleFinderController.vehicleSearch";
import getLead from "@salesforce/apex/VehicleFinderController.getLead";
import saveLead from "@salesforce/apex/VehicleFinderController.saveLead";

export default class VehicleFinder extends LightningElement {
    loaded = false;

    values = {
        minYear: 2000,
        maxYear: 2021
    };

    @api
    get recordId() {
        return this.values.recordId;
    }
    set recordId(value) {
        getLead({ recordId: value })
            .then(leadData => {
                this.changeStep(1);
                this.values = {
                    ...leadData,
                    recordId: value
                }
                this.handleFindMatches({ skipSave: true });
            })
    }

    vehicleMatches = [];

    //Wizard Variables
    step = {
        current: 0,
        customer: true
    }
    nextLabel = 'Next';
    prevLabel = 'Previous'
    hidePrevButton = false;
    hideNextButton = false;

    //Search Variables
    makeOptions = [];
    modelOptions = [];
    bodyOptions = [];
    colorOptions = [];

    @wire(getSearchOptions)
    seachOptions({ error, data }) {
        if (data) {
            this.makeOptions = [
                { label: '-No Preference-', value: '' },
                ...data.makes];
            this.modelOptions = [
                { label: '-No Preference-', value: '' },
                ...data.models];
            this.bodyOptions = [
                { label: '-No Preference-', value: '' },
                ...data.bodies];
            this.colorOptions = [
                { label: '-No Preference-', value: '' },
                ...data.colors];
            this.loaded = true;
        } else if (error) {
            console.error(error);
        }
    }

    get creditOptions() {
        return [
            { label: 'Excellent (720-850)', value: 'A' },
            { label: 'Good (690-719)', value: 'B' },
            { label: 'Fair (630-689)', value: 'C' },
            { label: 'Poor (530-629)', value: 'D' },
            { label: 'Bad (300-529)', value: 'F' },
        ];
    }

    handleChange(event) {
        this.values = {
            ...this.values,
            [event.target.dataset.id]: event.target.value
        }
    }

    handleCalculate() {
        if (this.values.credit && this.values.payment) {
            let rate;
            switch (this.values.credit) {
                case 'A':
                    rate = 2.7
                    break;
                case 'B':
                    rate = 6
                    break;
                case 'C':
                    rate = 10
                    break;
                case 'D':
                    rate = 14
                    break;
                case 'F':
                    rate = 24.0
                    break;
                default:
                    rate = 24.0
                    break;
            }
            var interest = parseFloat(rate) / 100 / 12;
            var payments = parseFloat(7) * 12; //Assume 7 year loan

            var d = Math.pow(1 + interest, payments);

            this.values = {
                ...this.values,
                estPrice: ((parseFloat(this.values.payment) / (d * interest)) * (d - 1)).toFixed(0)
            }
        }
    }

    handlePrevStep() {
        this.changeStep(this.step.current - 1);
    }

    handleNextStep() {
        this.changeStep(this.step.current + 1);
    }

    changeStep(step) {
        saveLead({ searchJSON: JSON.stringify(this.values) });
        if (step < 0) step = 0;
        if (step > 2) step = 2;
        switch (step) {
            case 0:
                //Customer
                this.step = { current: step, customer: true }
                break;
            case 1:
                //Vehcile -> Print
                this.step = { current: step, vehicle: true }
                break;
            case 2:
                //Print
                this.step = { current: step, print: true }
                break;
            default:
                break;
        }
    }

    handleFindMatches({ skipSave }) {
        if (!skipSave) {
            saveLead({ searchJSON: JSON.stringify(this.values) });
        }
        vehicleSearch({ searchJSON: JSON.stringify(this.values) })
            .then(result => {
                if (result) {
                    this.vehicleMatches = result;
                }
            })
    }
}