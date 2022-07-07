import React, { Component } from 'react';
import Layout from '../../../components/Layout';
import { Button, Input, Form, Message, Table } from 'semantic-ui-react';
import RecordRow from '../../../components/RecordRow';

import 'semantic-ui-css/semantic.min.css';

import { Link, Router } from '../../../routes';

import contract from '../../../ethereum/contract';
import web3 from '../../../ethereum/web3';

export async function getServerSideProps(props) {
    const { patientAddress } = props.query;

    let recordCount, patient;

    try
    {
        patient = await contract.methods.getpatient(patientAddress).call();
        
        // recordCount = await contract.methods.getRecordCount(patientAddress).call();

        recordCount = patient['2'];
    }
    catch(err)
    {
        console.log(err);
    }

    let records;
    
    if(recordCount)
    {
        // const recordNumbersList = await contract.methods.getRecordNumbers(patientAddress).call();

        const recordNumbersList = patient['3'];

        records = await Promise.all
        (
            recordNumbersList.map
            ( 
                (index) => contract.methods.recordList(index).call()
            )
        );
    }
    else
    {
        records = [];
    }

    return {
        props:
        {
            address: props.query.patientAddress,
            records: JSON.parse(JSON.stringify(records)),
            recordCount
        }
    };
}

class PatientShow extends Component {
    render() {
        const { Header, HeaderCell, Body, Row } = Table;

        const recordRows = this.props.records.map
            (
                (record, index) => {
                    return (
                        <RecordRow
                            key={index}
                            number={record['0']}
                            record={record}
                            routeStart={`/users/patients/${this.props.address}`}
                        />
                    );
                }
            );


        return (
            <Layout>
                <Table>
                    <Header>
                        <Row>
                            <HeaderCell textAlign='center'>Number</HeaderCell>
                            <HeaderCell textAlign='center'>Doctor</HeaderCell>
                            <HeaderCell textAlign='center'>Patient</HeaderCell>
                            <HeaderCell textAlign='center'></HeaderCell>
                        </Row>
                    </Header>
                    <Body>
                        {recordRows}
                    </Body>
                </Table>

                <div>Found {this.props.recordCount} record(s).</div>
            </Layout>
        );
    }
}

export default PatientShow;