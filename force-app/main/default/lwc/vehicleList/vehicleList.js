import { api, LightningElement } from 'lwc';

const columns = [
    { label: 'Cloud Score', fieldName: 'score', type: 'percent' },
    { label: 'Year', fieldName: 'year' },
    { label: 'Make', fieldName: 'make' },
    { label: 'Model', fieldName: 'model' },
    { label: 'Body Style', fieldName: 'bodyStyle' },
    { label: 'Color', fieldName: 'color' },
    { label: 'List Price', fieldName: 'price', type: 'currency' },
    { label: 'New/Used', fieldName: 'newUsed' },
    { label: 'Location', fieldName: 'location' },
];

export default class VehicleList extends LightningElement {
    columns = columns;

    @api vehicles = [];
}